#!/usr/bin/env bash

set -uo pipefail
shopt -s nocasematch

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

render_context() {
  local pane_id="${1:-}"
  local aws_profile
  local kube_config_paths
  local kube_config_path
  local kube_context=""
  local config_line
  local -a kube_config_files

  aws_profile="$(tmux show-environment -g "PANE_${pane_id}_AWS_PROFILE" 2>/dev/null || true)"
  aws_profile="${aws_profile#*=}"

  kube_config_paths="${KUBECONFIG:-${HOME}/.kube/config}"
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
      break 2
    done < "$kube_config_path"
  done

  [[ -n "$aws_profile" ]] && printf '#[fg=#eed49f,bold]   %s' "$aws_profile"
  [[ -n "$kube_context" ]] && printf '#[fg=#8aadf4,bold]    %s' "$kube_context"
  return 0
}

if [[ "${1:-}" == '--context' ]]; then
  render_context "${2:-}"
  exit 0
fi

agent_for_command() {
  local command_name
  command_name="${1##*/}"

  case "$command_name" in
    codex*) agent_name=codex ;;
    claude*) agent_name=claude ;;
    fx*) agent_name=fx ;;
    pi|pi-*|pi-coding-agent*) agent_name=pi ;;
    *) return 1 ;;
  esac
}

fallback_state() {
  local screen_content="$1"

  if [[ "$screen_content" =~ action\ required|permission\ required|waiting\ for\ approval|waiting\ for\ user\ confirmation|requires\ approval|allow\ command\?|press\ enter\ to\ confirm|enter\ to\ submit|do\ you\ want\ to\ proceed\?|run\ this\ command\?|asking\ user|enter\ your\ response ]]; then
    echo blocked
  elif [[ "$screen_content" =~ esc\ to\ cancel|esc\ cancel|esc\ to\ interrupt|ctrl\+c\ to\ interrupt|ctrl\+c\ to\ stop|esc\ to\ stop|working\.\.\.|kiro\ is\ working|\[stop\] ]]; then
    echo working
  else
    echo idle
  fi
}

detect_agent_state() {
  local agent_name="$1"
  local pane_id="$2"
  local pane_title="$3"
  local screen_content
  local recent_content
  local state
  local line

  case "$agent_name" in
    codex)
      [[ "$pane_title" == *"Action Required"* ]] && { echo blocked; return; }
      [[ "$pane_title" =~ (^|[[:space:]])[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]([[:space:]]|$) ]] && { echo working; return; }
      ;;
    claude)
      [[ "$pane_title" =~ ^[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏][[:space:]] ]] && { echo working; return; }
      ;;
    fx)
      screen_content="$(tmux capture-pane -p -t "$pane_id" -S -40 2>/dev/null)"
      recent_content="$(printf '%s\n' "$screen_content" | awk 'NF { lines[++n]=$0 } END { start=n-11; if (start<1) start=1; for (i=start;i<=n;i++) print lines[i] }')"
      state=idle

      while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]•]*(Pending[[:space:]]+(approval|trust)|Awaiting[[:space:]]+approval|Waiting[[:space:]]+for[[:space:]]+(approval|authorization|authentication))(:|[[:space:]]|$) ]]; then
          echo blocked
          return
        elif [[ "$line" =~ ^[[:space:]•]*(Running|Thinking|Working|Streaming|Connecting|Retrying)([[:space:]]|\(|$) ]]; then
          state=working
        fi
      done <<< "$recent_content"

      echo "$state"
      return
      ;;
  esac

  screen_content="$(tmux capture-pane -p -t "$pane_id" -S -120 2>/dev/null)"
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

  case "$state" in
    blocked) color="#ed8796"; icon="●" ;;
    working) color="#eed49f"; icon="◐" ;;
    *) color="#a6da95"; icon="✓" ;;
  esac

  printf '#[fg=%s,bold]   %s %s' "$color" "$icon" "$session_name"
}

display_session_name() {
  local agent_session_id="$1"
  local agent_session_name="$2"
  local agent_path="$3"
  local client_pid
  local process_pid
  local parent_pid
  local pane_rows
  local candidate_session_id
  local candidate_session_name
  local candidate_pane_pid
  local candidate_path
  local candidate_command
  local matching_session_count=0
  local matching_session_name=""

  if [[ "$agent_session_name" != codex\ * && "$agent_session_name" != fx\ * ]]; then
    echo "$agent_session_name"
    return
  fi

  pane_rows="${all_pane_rows:-}"
  while IFS=: read -r candidate_session_id candidate_session_name candidate_pane_id candidate_command candidate_path candidate_pane_pid candidate_title; do
    if [[ "$candidate_session_id" != "$agent_session_id" && "$candidate_path" == "$agent_path" && "$candidate_command" == nvim* ]]; then
      matching_session_count=$((matching_session_count + 1))
      matching_session_name="$candidate_session_name"
    fi
  done <<< "$pane_rows"

  if (( matching_session_count == 1 )); then
    echo "$matching_session_name"
    return
  fi

  while read -r client_pid; do
    process_pid="$client_pid"
    while [[ "$process_pid" =~ ^[0-9]+$ ]] && (( process_pid > 1 )); do
      while IFS=: read -r candidate_session_id candidate_session_name candidate_pane_id candidate_command candidate_path candidate_pane_pid candidate_title; do
        if [[ "$candidate_session_id" != "$agent_session_id" && "$candidate_pane_pid" == "$process_pid" ]]; then
          echo "$candidate_session_name"
          return
        fi
      done <<< "$pane_rows"

      parent_pid="$(ps -o ppid= -p "$process_pid" 2>/dev/null | tr -d '[:space:]')"
      [[ "$parent_pid" == "$process_pid" ]] && break
      process_pid="$parent_pid"
    done
  done < <(tmux list-clients -t "$agent_session_id" -F '#{client_pid}' 2>/dev/null)

  while IFS=: read -r candidate_session_id candidate_session_name candidate_pane_id candidate_command candidate_path candidate_pane_pid candidate_title; do
    if [[ "$candidate_session_id" != "$agent_session_id" && "$candidate_path" == "$agent_path" && "$candidate_command" == nvim* ]]; then
      echo "$candidate_session_name"
      return
    fi
  done <<< "$pane_rows"

  echo "$agent_session_name"
}

all_pane_rows="$(tmux list-panes -a -F '#{session_id}:#{session_name}:#{pane_id}:#{pane_current_command}:#{pane_current_path}:#{pane_pid}:#{pane_title}' 2>/dev/null)"

while IFS=: read -r session_id session_name; do
  session_state=""
  session_priority=0
  session_path=""

  while IFS=: read -r pane_session_id pane_session_name pane_id pane_command pane_path pane_pid pane_title; do
    [[ "$pane_session_id" == "$session_id" ]] || continue
    agent_for_command "$pane_command" || continue
    agent_state="$(detect_agent_state "$agent_name" "$pane_id" "$pane_title")"
    state_priority "$agent_state"

    if (( agent_priority > session_priority )); then
      session_state="$agent_state"
      session_priority="$agent_priority"
      session_path="$pane_path"
    fi
  done <<< "$all_pane_rows"

  if [[ -n "$session_state" ]]; then
    display_name="$(display_session_name "$session_id" "$session_name" "$session_path")"
    render_session "$session_state" "$display_name"
  fi
done < <(tmux list-sessions -F '#{session_id}:#{session_name}' 2>/dev/null)
