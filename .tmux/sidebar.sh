#!/bin/sh
set -eu

socket_path="$1"
current_session_id="$2"
content_width="${3:-}"
focused_pane_id="${4:-}"

if [ -z "$content_width" ]; then
  sidebar_width="$(tmux -S "$socket_path" show-options -Av -t "$current_session_id" side-status-width)"
  content_width=$((sidebar_width - 1))
fi
[ "$content_width" -ge 1 ] || content_width=1
if [ -z "$focused_pane_id" ]; then
  focused_pane_id="$(tmux -S "$socket_path" display-message -p -t "${current_session_id}:" '#{pane_id}')"
fi
row_indent="  "
row_indent_width=${#row_indent}

agent_title_format() {
  status_label="$1"
  title_width=$((content_width - row_indent_width - 5 - ${#status_label}))
  pi_title_width=$((title_width + 1))
  default_title_format=""
  pi_title_format=""
  if [ "$title_width" -gt 0 ]; then
    default_title_format="#{s/[#]/\0\0/:#{=${title_width}:#{@sidebar_agent_title}}}"
  fi
  if [ "$pi_title_width" -gt 0 ]; then
    pi_title_format="#{s/[#]/\0\0/:#{=${pi_title_width}:#{@sidebar_agent_title}}}"
  fi
  printf '%s' "#{?#{==:#{@sidebar_agent_icon},π},${pi_title_format},${default_title_format}}"
}

branch_width=$((content_width - row_indent_width - 11))
branch_width_without_pr=$((content_width - row_indent_width - 1))
agent_label='#{?#{==:#{@sidebar_agent_state},blocked},action,#{?#{==:#{@sidebar_agent_state},working},Working,Idle}}'
agent_color='#{?#{==:#{@sidebar_agent_state},blocked},#ed8796,#{?#{==:#{@sidebar_agent_state},working},#eed49f,#a6da95}}'
agent_icon_gap='#{?#{==:#{@sidebar_agent_icon},π}, ,  }'
pr_label='#{?#{==:#{@sidebar_pr_state},open},Open,#{?#{==:#{@sidebar_pr_state},merged},Merged,Closed}}'
pr_color='#{?#{==:#{@sidebar_pr_state},open},#a6da95,#{?#{==:#{@sidebar_pr_state},merged},#c6a0f6,#ed8796}}'
pr_icon='#{?#{==:#{@sidebar_pr_state},merged},,#{?#{==:#{@sidebar_pr_state},closed},,}}'
agent_title="#{?#{==:#{@sidebar_agent_state},blocked},$(agent_title_format action),#{?#{==:#{@sidebar_agent_state},working},$(agent_title_format Working),$(agent_title_format Idle)}}"
branch_name=""
branch_name_without_pr=""
if [ "$branch_width" -gt 0 ]; then
  branch_name="#{s/[#]/\0\0/:#{p-${branch_width};=${branch_width}:#{@sidebar_branch}#{@sidebar_branch_sync}}}"
fi
if [ "$branch_width_without_pr" -gt 0 ]; then
  branch_name_without_pr="#{s/[#]/\0\0/:#{p-${branch_width_without_pr};=${branch_width_without_pr}:#{@sidebar_branch}#{@sidebar_branch_sync}}}"
fi
session_name="#{s/[#]/\0\0/:#{p${content_width};=${content_width}: #{session_name}}}"
session_rows="$(tmux -S "$socket_path" list-sessions -O index -f '#{!:#{@sidebar_source_session}}' -F '#{session_id} #{@sidebar_agent_panes}')"
set --
while read -r session_id pane_ids; do
  [ -n "$session_id" ] || continue
  session_color="#a4adca"
  session_weight=nobold
  if [ "$session_id" = "$current_session_id" ]; then
    session_color="#c6a0f6"
    session_weight=bold
  fi
  session_heading="#[nl]#[align=left,fg=${session_color},${session_weight},range=session|${session_id}]${session_name}#[norange,default,nl]"
  set -- "$@" display-message -p -t "${session_id}:" "$session_heading" ';'
  agent_spacing=""
  for pane_id in $pane_ids; do
    title_weight=nobold
    if [ "$pane_id" = "$focused_pane_id" ]; then
      title_weight=bold
    fi
    agent_range="#[range=user|agent${pane_id#%}]"
    pr_status="#[range=user|prpane${pane_id#%}]#[fg=${pr_color}]${pr_icon}  #{p6:${pr_label}} "
    branch_status="#{?@sidebar_pr_state,${pr_status}${agent_range}#[fg=#5b6078]${branch_name},#[fg=#5b6078]${branch_name_without_pr}}"
    agent_line="${agent_spacing}#[align=left,nobold]${agent_range}${row_indent}#[fg=${agent_color}]#{@sidebar_agent_icon}${agent_icon_gap}${agent_label} #[fg=#a4adca,${title_weight}]${agent_title} #[norange,default,nl]"
    branch_line="#[align=left,nobold]${agent_range}${row_indent}${branch_status} #[norange,default,nl]"
    set -- "$@" display-message -p -t "$pane_id" "${agent_line}${branch_line}" ';'
    agent_spacing='#[nl]'
  done
done <<EOF
$session_rows
EOF
[ "$#" -gt 0 ] || exit 0

tmux -S "$socket_path" "$@" |
  awk '
    { printf "%s", $0 }
    END { printf "\n" }
  '
