#!/usr/bin/env bash

set -uo pipefail

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

agent_for_command() {
  local command_name
  command_name="$(basename "$1" | tr '[:upper:]' '[:lower:]')"

  case "$command_name" in
    codex*) echo codex ;;
    claude*) echo claude ;;
    pi|pi-*|pi-coding-agent*) echo pi ;;
    *) return 1 ;;
  esac
}

fallback_state() {
  local screen_content="$1"
  local lowercase_content
  lowercase_content="$(printf '%s' "$screen_content" | tr '[:upper:]' '[:lower:]')"

  if [[ "$lowercase_content" =~ action\ required|permission\ required|waiting\ for\ approval|waiting\ for\ user\ confirmation|requires\ approval|allow\ command\?|press\ enter\ to\ confirm|enter\ to\ submit|do\ you\ want\ to\ proceed\?|run\ this\ command\?|asking\ user|enter\ your\ response ]]; then
    echo blocked
  elif [[ "$lowercase_content" =~ esc\ to\ cancel|esc\ cancel|esc\ to\ interrupt|ctrl\+c\ to\ interrupt|ctrl\+c\ to\ stop|esc\ to\ stop|working\.\.\.|kiro\ is\ working|\[stop\] ]]; then
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
  local state

  case "$agent_name" in
    codex)
      [[ "$pane_title" == *"Action Required"* ]] && { echo blocked; return; }
      [[ "$pane_title" =~ (^|[[:space:]])[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]([[:space:]]|$) ]] && { echo working; return; }
      ;;
    claude)
      [[ "$pane_title" =~ ^[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏][[:space:]] ]] && { echo working; return; }
      ;;
  esac

  screen_content="$(tmux capture-pane -p -t "$pane_id" -S -120 2>/dev/null)"
  fallback_state "$screen_content"
}

state_priority() {
  case "$1" in
    blocked) echo 3 ;;
    working) echo 2 ;;
    idle) echo 1 ;;
    *) echo 0 ;;
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

  if [[ "$agent_session_name" != codex\ * ]]; then
    echo "$agent_session_name"
    return
  fi

  pane_rows="$(tmux list-panes -a -F '#{session_id}:#{session_name}:#{pane_pid}:#{pane_current_path}:#{pane_current_command}' 2>/dev/null)"
  while read -r client_pid; do
    process_pid="$client_pid"
    while [[ "$process_pid" =~ ^[0-9]+$ ]] && (( process_pid > 1 )); do
      while IFS=: read -r candidate_session_id candidate_session_name candidate_pane_pid candidate_path candidate_command; do
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

  while IFS=: read -r candidate_session_id candidate_session_name candidate_pane_pid candidate_path candidate_command; do
    if [[ "$candidate_session_id" != "$agent_session_id" && "$candidate_path" == "$agent_path" && "$candidate_command" == nvim* ]]; then
      echo "$candidate_session_name"
      return
    fi
  done <<< "$pane_rows"

  echo "$agent_session_name"
}

while IFS=: read -r session_id session_name; do
  session_state=""
  session_priority=0
  session_path=""

  while IFS=: read -r pane_id pane_command pane_path pane_title; do
    agent_name="$(agent_for_command "$pane_command")" || continue
    agent_state="$(detect_agent_state "$agent_name" "$pane_id" "$pane_title")"
    agent_priority="$(state_priority "$agent_state")"

    if (( agent_priority > session_priority )); then
      session_state="$agent_state"
      session_priority="$agent_priority"
      session_path="$pane_path"
    fi
  done < <(tmux list-panes -s -t "$session_id" -F '#{pane_id}:#{pane_current_command}:#{pane_current_path}:#{pane_title}' 2>/dev/null)

  if [[ -n "$session_state" ]]; then
    display_name="$(display_session_name "$session_id" "$session_name" "$session_path")"
    render_session "$session_state" "$display_name"
  fi
done < <(tmux list-sessions -F '#{session_id}:#{session_name}' 2>/dev/null)
