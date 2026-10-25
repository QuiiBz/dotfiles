#!/usr/bin/env bash
set -euo pipefail

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
declare -A pane_widths=()
declare -A pane_targets=()
declare -a render_commands=()
render_command_bytes=0
rendered_rows=""

flush_render_commands() {
  ((${#render_commands[@]} > 0)) || return 0
  local batch_output
  batch_output="$(tmux -S "$socket_path" "${render_commands[@]}")" || return
  rendered_rows+="$batch_output"$'\n'
  render_commands=()
  render_command_bytes=0
}

queue_render_command() {
  local target="$1"
  local line_format="$2"
  local LC_ALL=C
  local command_bytes=$((${#target} + ${#line_format} + 32))

  if (( render_command_bytes + command_bytes > 12000 )); then
    flush_render_commands
  fi
  render_commands+=(display-message -p -t "$target" "$line_format" ';')
  render_command_bytes=$((render_command_bytes + command_bytes))
}

agent_title_format() {
  local status_label="$1"
  local title_width=$((content_width - row_indent_width - 5 - ${#status_label}))
  local pi_title_width=$((title_width + 1))
  local default_title_format=""
  local pi_title_format=""
  if [ "$title_width" -gt 0 ]; then
    default_title_format="#{s/[#]/\0\0/:#{=${title_width}:#{@sidebar_agent_title}}}"
  fi
  if [ "$pi_title_width" -gt 0 ]; then
    pi_title_format="#{s/[#]/\0\0/:#{=${pi_title_width}:#{@sidebar_agent_title}}}"
  fi
  printf -v "$2" '%s' "#{?#{==:#{@sidebar_agent_icon},π},${pi_title_format},${default_title_format}}"
}

branch_width_without_pr=$((content_width - row_indent_width - 1))
agent_label='#{?#{==:#{@sidebar_agent_state},blocked},action,#{?#{==:#{@sidebar_agent_state},working},Working,Idle}}'
agent_color='#{?#{==:#{@sidebar_agent_state},blocked},#ed8796,#{?#{==:#{@sidebar_agent_state},working},#eed49f,#a6da95}}'
agent_icon_gap='#{?#{==:#{@sidebar_agent_icon},π}, ,  }'
pr_color='#{?#{==:#{@sidebar_pr_state},open},#a6da95,#{?#{==:#{@sidebar_pr_state},merged},#c6a0f6,#ed8796}}'
pr_icon='#{?#{==:#{@sidebar_pr_state},merged},,#{?#{==:#{@sidebar_pr_state},closed},,}}'
agent_title_format action blocked_agent_title
agent_title_format Working working_agent_title
agent_title_format Idle idle_agent_title
agent_title="#{?#{==:#{@sidebar_agent_state},blocked},${blocked_agent_title},#{?#{==:#{@sidebar_agent_state},working},${working_agent_title},${idle_agent_title}}}"
branch_name_without_pr=""
if [ "$branch_width_without_pr" -gt 0 ]; then
  branch_name_without_pr="#{s/[#]/\0\0/:#{p-${branch_width_without_pr};=${branch_width_without_pr}:#{@sidebar_branch}#{@sidebar_branch_sync}}}"
fi
session_name="#{s/[#]/\0\0/:#{p${content_width};=${content_width}: #{session_name}}}"
snapshot="$(tmux -S "$socket_path" \
  list-sessions -O index -f '#{!:#{@sidebar_source_session}}' -F '#{session_id}|#{@sidebar_agent_panes}|#{@sidebar_agent_groups}|#{pane_id}' \
  ';' list-panes -a -F 'P#{pane_id}|#{@sidebar_source_pane}|#{@sidebar_pr_state}|#{w:#{s/[#]/\0\0/:#{@sidebar_branch}#{@sidebar_branch_sync}}}|#{w:#{s/[#]/\0\0/:#{@sidebar_pr_title}}}')"
session_rows=""
while IFS= read -r snapshot_row; do
  case "$snapshot_row" in
    P*)
      pane_row="${snapshot_row#P}"
      pane_id="${pane_row%%|*}"
      pane_row="${pane_row#*|}"
      pane_targets[$pane_id]="${pane_row%%|*}"
      pane_widths[$pane_id]="${pane_row#*|}"
      ;;
    *) session_rows+="$snapshot_row"$'\n' ;;
  esac
done <<< "$snapshot"
while IFS='|' read -r session_id pane_ids pane_groups active_pane_id; do
  [ -n "$session_id" ] || continue
  session_color="#a4adca"
  session_weight=nobold
  if [ "$session_id" = "$current_session_id" ]; then
    session_color="#c6a0f6"
    session_weight=bold
  fi
  session_heading="#[nl]#[align=left,fg=${session_color},${session_weight},range=session|${session_id}]${session_name}#[norange,default,nl]"
  queue_render_command "${session_id}:" "$session_heading"
  group_spacing=""
  repository_only=false
  if [ -z "$pane_ids" ]; then
    pane_groups="$active_pane_id"
    repository_only=true
  elif [ -z "$pane_groups" ]; then
    pane_groups="$pane_ids"
  fi
  for pane_group in $pane_groups; do
    IFS=, read -r -a group_pane_ids <<< "$pane_group"
    repository_pane_id=""
    for pane_id in "${group_pane_ids[@]}"; do
      [[ -v pane_widths[$pane_id] ]] || continue
      [ -n "$repository_pane_id" ] || repository_pane_id="$pane_id"
      title_weight=nobold
      target_pane_id="${pane_targets[$pane_id]:-$pane_id}"
      if [ "$target_pane_id" = "$focused_pane_id" ]; then
        title_weight=bold
        repository_pane_id="$pane_id"
      fi
      if [ "$repository_only" = false ]; then
        agent_range="#[range=user|agent${target_pane_id#%}]"
        agent_line="${group_spacing}#[align=left,nobold]${agent_range}${row_indent}#[fg=${agent_color}]#{@sidebar_agent_icon}${agent_icon_gap}${agent_label} #[fg=#a4adca,${title_weight}]${agent_title} #[norange,default,nl]"
        queue_render_command "$pane_id" "$agent_line"
        group_spacing=""
      fi
    done
    [ -n "$repository_pane_id" ] || continue
    target_pane_id="${pane_targets[$repository_pane_id]:-$repository_pane_id}"
    agent_range="#[range=user|agent${target_pane_id#%}]"
    IFS='|' read -r pr_state branch_text_width pr_title_text_width <<< "${pane_widths[$repository_pane_id]}"
    branch_status="#[fg=#5b6078]${branch_name_without_pr}"
    if [ -n "$pr_state" ]; then
      text_width=$((content_width - row_indent_width - 5))
      [ "$text_width" -ge 0 ] || text_width=0
      branch_width=$((text_width / 2))
      [ "$branch_text_width" -ge "$branch_width" ] || branch_width="$branch_text_width"
      pr_title_width=$((text_width - branch_width))
      [ "$pr_title_text_width" -ge "$pr_title_width" ] || pr_title_width="$pr_title_text_width"
      branch_width=$((text_width - pr_title_width))
      pr_title=""
      branch_name=""
      if [ "$pr_title_width" -gt 0 ]; then
        pr_title="#{s/[#]/\0\0/:#{=${pr_title_width}:#{@sidebar_pr_title}}}"
      fi
      if [ "$branch_width" -gt 0 ]; then
        branch_name="#{s/[#]/\0\0/:#{p-${branch_width};=${branch_width}:#{@sidebar_branch}#{@sidebar_branch_sync}}}"
      fi
      pr_status="#[range=user|prpane${repository_pane_id#%}]#[fg=${pr_color}]${pr_icon}  #[fg=#CAD3F5]${pr_title} "
      branch_status="${pr_status}${agent_range}#[fg=#5b6078]${branch_name}"
    fi
    branch_line="${group_spacing}#[align=left,nobold]${agent_range}${row_indent}${branch_status} #[norange,default,nl]"
    queue_render_command "$repository_pane_id" "$branch_line"
    group_spacing='#[nl]'
  done
done <<< "$session_rows"
flush_render_commands
printf '%s\n' "${rendered_rows//$'\n'/}"
