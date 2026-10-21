#!/bin/sh
set -eu

socket_path="$1"
current_session_id="$2"
content_width="${3:-}"

if [ -z "$content_width" ]; then
  sidebar_width="$(tmux -S "$socket_path" show-options -v -t "$current_session_id" side-status-width)"
  content_width=$((sidebar_width - 1))
fi
[ "$content_width" -ge 1 ] || content_width=1

status_width=11
[ "$status_width" -le "$content_width" ] || status_width="$content_width"
name_width=$((content_width - status_width))
session_name="#{s/[#]/\0\0/:#{p${content_width};=${content_width}: #{session_name}}}"
session_name_with_status=""
if [ "$name_width" -gt 0 ]; then
  session_name_with_status="#{s/[#]/\0\0/:#{p${name_width};=${name_width}: #{session_name}}}"
fi

session_color="#{?#{==:#{session_id},${current_session_id}},#c6a0f6,#a4adca}"
codex_color='#{?#{==:#{@codex_state},blocked},#ed8796,#{?#{==:#{@codex_state},working},#eed49f,#a6da95}}'
codex_label='#{?#{==:#{@codex_state},blocked},● action,#{?#{==:#{@codex_state},working},◐ Working,✓ Idle}}'
status_text_width=$((status_width - 1))
codex_status=" "
if [ "$status_text_width" -gt 0 ]; then
  codex_status="#[fg=${codex_color}]#{p-${status_text_width};=${status_text_width}:${codex_label}} "
fi
session_heading="#{?@codex_state,${session_name_with_status}${codex_status},${session_name}}"
demo_active='#{&&:#{==:#{@sidebar_demo},on},#{@sidebar_demo_pr_title}}'
branch_label="#{?${demo_active},#{@sidebar_demo_branch},#{@sidebar_branch}#{@sidebar_branch_sync}}"
pr_state="#{?${demo_active},#{@sidebar_demo_pr_state},#{@sidebar_pr_state}}"
pr_title="#{?${demo_active},#{@sidebar_demo_pr_title},#{@sidebar_pr_title}}"
branch_name="#{s/[#]/\0\0/:#{p${content_width};=${content_width}:   ${branch_label}}}"
branch_status="#{?${branch_label},#[nl]#[fg=#5b6078]#[nobold]${branch_name},}"
pr_color="#{?#{==:${pr_state},open},#a6da95,#{?#{==:${pr_state},merged},#c6a0f6,#ed8796}}"
pr_icon="#{?#{==:${pr_state},open},,#{?#{==:${pr_state},merged},,}}"
pr_indent_width=3
[ "$content_width" -ge 5 ] || pr_indent_width=$((content_width - 1))
pr_indent="$(printf '%*s' "$pr_indent_width" '')"
# Leave room for Nerd Font glyphs that extend into the next cell.
pr_gap_width=2
pr_available_width=$((content_width - pr_indent_width - 1))
[ "$pr_gap_width" -le "$pr_available_width" ] || pr_gap_width="$pr_available_width"
pr_gap="$(printf '%*s' "$pr_gap_width" '')"
pr_name="${pr_indent}#[fg=${pr_color}]${pr_icon}${pr_gap}#[fg=#CAD3F5]"
pr_title_width=$((pr_available_width - pr_gap_width))
if [ "$pr_title_width" -gt 0 ]; then
  pr_name="${pr_name}#{s/[#]/\0\0/:#{p${pr_title_width};=${pr_title_width}:${pr_title}}}"
fi
pr_status="#{?${pr_title},#[nl]#[range=user|pr#{s/[$]//:session_id}]#[nobold]${pr_name},}"
session_format="#[align=left,fg=${session_color},bold,range=session|#{session_id}]${session_heading}${branch_status}${pr_status}#[norange,default,nl]"

tmux -S "$socket_path" list-sessions -F "$session_format" |
  awk '
    BEGIN { printf "#[nl]" }
    NR > 1 { printf "#[nl]" }
    { printf "%s", $0 }
    END { printf "\n" }
  '
