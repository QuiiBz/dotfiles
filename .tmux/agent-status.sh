#!/usr/bin/env bash

set -uo pipefail
shopt -s nocasematch

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

field_separator=$'\x1f'
marker_prefix="__TMUX_AGENT_${$}_PANE__"
environment_marker="__TMUX_AGENT_${$}_ENV_END__"
all_environment_rows=""
all_pane_rows=""
all_session_rows=""
all_client_rows=""
legacy_pane_rows=""
process_tree_loaded=false
declare -A legacy_contexts=()
declare -A pane_contents=()
declare -A process_parents=()

agent_for_command() {
  local command_name="${1##*/}"

  case "$command_name" in
    codex*) agent_name=codex ;;
    claude*) agent_name=claude ;;
    fx*) agent_name=fx ;;
    pi|pi-*) agent_name=pi ;;
    *) return 1 ;;
  esac
}

fallback_state() {
  local screen_content="$1"

  if [[ "$screen_content" =~ action\ required|permission\ required|waiting\ for\ approval|waiting\ for\ user\ confirmation|requires\ approval|allow\ command\?|press\ enter\ to\ confirm|enter\ to\ submit|do\ you\ want\ to\ proceed\?|run\ this\ command\?|asking\ user|enter\ your\ response ]]; then
    detected_state=blocked
  elif [[ "$screen_content" =~ esc\ to\ cancel|esc\ cancel|esc\ to\ interrupt|ctrl\+c\ to\ interrupt|ctrl\+c\ to\ stop|esc\ to\ stop|working\.\.\.|kiro\ is\ working|\[stop\] ]]; then
    detected_state=working
  else
    detected_state=idle
  fi
}

detect_fx_state() {
  local screen_content="$1"
  local line
  local -a nonempty_lines=()
  local start_index

  while IFS= read -r line; do
    [[ -n "$line" ]] && nonempty_lines+=("$line")
  done <<< "$screen_content"

  start_index=$((${#nonempty_lines[@]} - 12))
  (( start_index < 0 )) && start_index=0
  detected_state=idle

  for ((i = start_index; i < ${#nonempty_lines[@]}; i++)); do
    line="${nonempty_lines[$i]}"
    if [[ "$line" =~ ^[[:space:]•]*(Pending[[:space:]]+(approval|trust)|Awaiting[[:space:]]+approval|Waiting[[:space:]]+for[[:space:]]+(approval|authorization|authentication))(:|[[:space:]]|$) ]]; then
      detected_state=blocked
      return
    elif [[ "$line" =~ ^[[:space:]•]*(Running|Thinking|Working|Streaming|Connecting|Retrying)([[:space:]]|\(|$) ]]; then
      detected_state=working
    fi
  done
}

detect_agent_state() {
  local current_agent_name="$1"
  local pane_id="$2"
  local pane_title="$3"
  local screen_content="${pane_contents[$pane_id]:-}"

  case "$current_agent_name" in
    codex)
      [[ "$pane_title" == *"Action Required"* ]] && { detected_state=blocked; return; }
      [[ "$pane_title" =~ (^|[[:space:]])[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]([[:space:]]|$) ]] && { detected_state=working; return; }
      ;;
    claude)
      [[ "$pane_title" =~ ^[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏][[:space:]] ]] && { detected_state=working; return; }
      ;;
    fx)
      detect_fx_state "$screen_content"
      return
      ;;
  esac

  fallback_state "$screen_content"
}

state_priority() {
  case "$1" in
    blocked) agent_priority=3 ;;
    working) agent_priority=2 ;;
    idle) agent_priority=1 ;;
    *) agent_priority=0 ;;
  esac
}

render_session() {
  local state="$1"
  local session_name="${2//#/##}"
  local color
  local icon
  local rendered_session

  case "$state" in
    blocked) color="#ed8796"; icon="●" ;;
    working) color="#eed49f"; icon="◐" ;;
    *) color="#a6da95"; icon="✓" ;;
  esac

  printf -v rendered_session '#[fg=%s,bold]   %s %s' "$color" "$icon" "$session_name"
  rendered_status+="$rendered_session"
}

load_process_tree() {
  local process_pid
  local parent_pid
  local process_rows

  [[ "$process_tree_loaded" == true ]] && return
  process_rows="$(ps -axo pid=,ppid= 2>/dev/null || true)"
  while read -r process_pid parent_pid; do
    [[ -n "$process_pid" ]] && process_parents[$process_pid]="$parent_pid"
  done <<< "$process_rows"
  process_tree_loaded=true
}

display_session_name() {
  local agent_session_id="$1"
  local agent_session_name="$2"
  local agent_path="$3"
  local row_type
  local candidate_session_id
  local candidate_session_name
  local _candidate_pane_id
  local candidate_command
  local candidate_path
  local candidate_pane_pid
  local _candidate_title
  local client_session_id
  local client_pid
  local process_pid
  local parent_pid
  local matching_session_count=0
  local matching_session_name=""

  display_name="$agent_session_name"
  if [[ "$agent_session_name" != codex\ * && "$agent_session_name" != fx\ * ]]; then
    return
  fi

  while IFS="$field_separator" read -r row_type candidate_session_id candidate_session_name _candidate_pane_id candidate_command candidate_path candidate_pane_pid _candidate_title; do
    if [[ "$candidate_session_id" != "$agent_session_id" && "$candidate_path" == "$agent_path" && "$candidate_command" == nvim* ]]; then
      matching_session_count=$((matching_session_count + 1))
      matching_session_name="$candidate_session_name"
    fi
  done <<< "$all_pane_rows"

  if (( matching_session_count == 1 )); then
    display_name="$matching_session_name"
    return
  fi

  load_process_tree
  while IFS="$field_separator" read -r row_type client_session_id client_pid; do
    [[ "$client_session_id" == "$agent_session_id" ]] || continue
    process_pid="$client_pid"
    while [[ "$process_pid" =~ ^[0-9]+$ ]] && (( process_pid > 1 )); do
      while IFS="$field_separator" read -r row_type candidate_session_id candidate_session_name _candidate_pane_id candidate_command candidate_path candidate_pane_pid _candidate_title; do
        if [[ "$candidate_session_id" != "$agent_session_id" && "$candidate_pane_pid" == "$process_pid" ]]; then
          display_name="$candidate_session_name"
          return
        fi
      done <<< "$all_pane_rows"

      parent_pid="${process_parents[$process_pid]:-}"
      [[ -z "$parent_pid" || "$parent_pid" == "$process_pid" ]] && break
      process_pid="$parent_pid"
    done
  done <<< "$all_client_rows"

  while IFS="$field_separator" read -r row_type candidate_session_id candidate_session_name _candidate_pane_id candidate_command candidate_path candidate_pane_pid _candidate_title; do
    if [[ "$candidate_session_id" != "$agent_session_id" && "$candidate_path" == "$agent_path" && "$candidate_command" == nvim* ]]; then
      display_name="$candidate_session_name"
      return
    fi
  done <<< "$all_pane_rows"
}

load_snapshot() {
  local snapshot
  local row_type
  local row
  local reading_environment=true

  snapshot="$(tmux show-environment -g \
    \; display-message -p "$environment_marker" \
    \; list-panes -a -F "P${field_separator}#{session_id}${field_separator}#{session_name}${field_separator}#{pane_id}${field_separator}#{pane_current_command}${field_separator}#{pane_current_path}${field_separator}#{pane_pid}${field_separator}#{pane_title}" \
    \; list-sessions -F "S${field_separator}#{session_id}${field_separator}#{session_name}" \
    \; list-clients -F "C${field_separator}#{session_id}${field_separator}#{client_pid}" \
    \; list-panes -a -f '#{!=:#{@status_context_managed},1}' -F "L${field_separator}#{pane_id}" 2>/dev/null)" || return 1

  all_environment_rows=""
  all_pane_rows=""
  all_session_rows=""
  all_client_rows=""
  legacy_pane_rows=""
  while IFS= read -r row; do
    if [[ "$row" == "$environment_marker" ]]; then
      reading_environment=false
      continue
    elif [[ "$reading_environment" == true ]]; then
      all_environment_rows+="${row}"$'\n'
      continue
    fi

    row_type="${row%%"$field_separator"*}"
    case "$row_type" in
      P) all_pane_rows+="${row}"$'\n' ;;
      S) all_session_rows+="${row}"$'\n' ;;
      C) all_client_rows+="${row}"$'\n' ;;
      L) legacy_pane_rows+="${row}"$'\n' ;;
    esac
  done <<< "$snapshot"
}

capture_agent_panes() {
  local row_type
  local session_id
  local session_name
  local pane_id
  local pane_command
  local pane_path
  local _pane_pid
  local pane_title
  local capture_output
  local current_pane_id=""
  local line
  local -a tmux_commands=()

  pane_contents=()
  while IFS="$field_separator" read -r row_type session_id session_name pane_id pane_command pane_path _pane_pid pane_title; do
    agent_for_command "$pane_command" || continue
    tmux_commands+=(display-message -p -t "$pane_id" "${marker_prefix}${pane_id#%}" ';')
    tmux_commands+=(capture-pane -p -t "$pane_id" -S -120 ';')
  done <<< "$all_pane_rows"

  ((${#tmux_commands[@]} > 0)) || return 0
  unset "tmux_commands[${#tmux_commands[@]}-1]"
  capture_output="$(tmux "${tmux_commands[@]}" 2>/dev/null)"

  while IFS= read -r line; do
    if [[ "$line" == "$marker_prefix"* ]]; then
      current_pane_id="%${line#"$marker_prefix"}"
      pane_contents[$current_pane_id]=""
    elif [[ -n "$current_pane_id" ]]; then
      pane_contents[$current_pane_id]+="${line}"$'\n'
    fi
  done <<< "$capture_output"
}

build_agent_status() {
  local row_type
  local session_id
  local session_name
  local pane_session_id
  local _pane_session_name
  local pane_id
  local pane_command
  local pane_path
  local _pane_pid
  local pane_title
  local session_state
  local session_priority
  local session_path

  load_snapshot || return 1
  update_legacy_contexts
  capture_agent_panes
  process_tree_loaded=false
  process_parents=()
  rendered_status=""

  while IFS="$field_separator" read -r row_type session_id session_name; do
    session_state=""
    session_priority=0
    session_path=""

    while IFS="$field_separator" read -r row_type pane_session_id _pane_session_name pane_id pane_command pane_path _pane_pid pane_title; do
      [[ "$pane_session_id" == "$session_id" ]] || continue
      agent_for_command "$pane_command" || continue
      detect_agent_state "$agent_name" "$pane_id" "$pane_title"
      state_priority "$detected_state"

      if (( agent_priority > session_priority )); then
        session_state="$detected_state"
        session_priority="$agent_priority"
        session_path="$pane_path"
      fi
    done <<< "$all_pane_rows"

    if [[ -n "$session_state" ]]; then
      display_session_name "$session_id" "$session_name" "$session_path"
      render_session "$session_state" "$display_name"
    fi
  done <<< "$all_session_rows"
}

read_kube_context() {
  local kube_config_paths="${1:-${HOME}/.kube/config}"
  local kube_config_path
  local config_line
  local -a kube_config_files

  kube_context=""
  IFS=':' read -r -a kube_config_files <<< "$kube_config_paths"
  for kube_config_path in "${kube_config_files[@]}"; do
    [[ -r "$kube_config_path" ]] || continue
    while IFS= read -r config_line; do
      [[ "$config_line" == current-context:* ]] || continue
      kube_context="${config_line#current-context:}"
      kube_context="${kube_context#"${kube_context%%[![:space:]]*}"}"
      kube_context="${kube_context%"${kube_context##*[![:space:]]}"}"
      kube_context="${kube_context#\"}"
      kube_context="${kube_context%\"}"
      return
    done < "$kube_config_path"
  done
}

render_context() {
  local aws_profile="${1//#/##}"
  local escaped_kube_context="${2//#/##}"

  rendered_context=""
  [[ -n "$aws_profile" ]] && printf -v rendered_context '#[fg=#eed49f,bold]   %s' "$aws_profile"
  if [[ -n "$escaped_kube_context" ]]; then
    printf -v rendered_context '%s#[fg=#8aadf4,bold]    %s' "$rendered_context" "$escaped_kube_context"
  fi
}

update_legacy_contexts() {
  local environment_line
  local variable_name
  local pane_id
  local aws_profile
  local row_type
  local -A aws_profiles=()
  local -a tmux_commands=()

  while IFS= read -r environment_line; do
    [[ "$environment_line" == PANE_%*_AWS_PROFILE=* ]] || continue
    variable_name="${environment_line%%=*}"
    pane_id="${variable_name#PANE_}"
    pane_id="${pane_id%_AWS_PROFILE}"
    aws_profiles[$pane_id]="${environment_line#*=}"
  done <<< "$all_environment_rows"

  read_kube_context "${KUBECONFIG:-${HOME}/.kube/config}"
  while IFS="$field_separator" read -r row_type pane_id; do
    [[ -n "$pane_id" ]] || continue
    aws_profile="${aws_profiles[$pane_id]:-}"
    render_context "$aws_profile" "$kube_context"
    [[ "${legacy_contexts[$pane_id]:-}" == "$rendered_context" ]] && continue
    tmux_commands+=(set-option -pq -t "$pane_id" @status_context "$rendered_context" ';')
    legacy_contexts[$pane_id]="$rendered_context"
  done <<< "$legacy_pane_rows"

  ((${#tmux_commands[@]} > 0)) || return 0
  unset "tmux_commands[${#tmux_commands[@]}-1]"
  tmux "${tmux_commands[@]}" 2>/dev/null
}

watch_status() {
  local existing_watcher_pid
  local refresh_interval
  local continuum_interval
  local next_save_time
  local timer_pipe
  local last_rendered_status=""

  existing_watcher_pid="$(tmux show-option -gqv @agent-status-watcher-pid 2>/dev/null || true)"
  if [[ "$existing_watcher_pid" =~ ^[0-9]+$ && "$existing_watcher_pid" != "$$" ]] && kill -0 "$existing_watcher_pid" 2>/dev/null; then
    kill -HUP "$existing_watcher_pid"
    return
  fi

  refresh_interval="$(tmux show-option -gqv @agent-status-interval 2>/dev/null || true)"
  [[ "$refresh_interval" =~ ^[1-9][0-9]*$ ]] || refresh_interval=5
  continuum_interval="$(tmux show-option -gqv @continuum-save-interval 2>/dev/null || true)"
  [[ "$continuum_interval" =~ ^[1-9][0-9]*$ ]] || continuum_interval=15
  next_save_time=$((SECONDS + continuum_interval * 60))

  tmux set-option -gq @agent-status-watcher-pid "$$"
  trap 'exec "${BASH_SOURCE[0]}" --watch' HUP
  trap 'tmux set-option -guq @agent-status-watcher-pid 2>/dev/null || true' EXIT

  timer_pipe="/tmp/tmux-agent-status-${$}.pipe"
  mkfifo "$timer_pipe"
  exec 9<> "$timer_pipe"
  rm -f "$timer_pipe"

  while build_agent_status; do
    if [[ "$rendered_status" != "$last_rendered_status" ]]; then
      tmux set-option -gq @agent_status "$rendered_status"
      last_rendered_status="$rendered_status"
    fi

    if (( SECONDS >= next_save_time )); then
      "${HOME}/.tmux/plugins/continuum/scripts/continuum_save.sh"
      next_save_time=$((SECONDS + continuum_interval * 60))
    fi

    read -r -t "$refresh_interval" -u 9 _ || true
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1:-}" in
    --watch)
      watch_status
      ;;
    --update)
      build_agent_status
      tmux set-option -gq @agent_status "$rendered_status"
      ;;
    *)
      build_agent_status
      printf '%s' "$rendered_status"
      ;;
  esac
fi
