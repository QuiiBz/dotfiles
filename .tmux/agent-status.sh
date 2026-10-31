#!/usr/bin/env bash

set -uo pipefail
shopt -s nocasematch

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

field_separator=$'\x1f'
environment_marker="__TMUX_AGENT_${$}_ENV_END__"
all_environment_rows=""
all_pane_rows=""
all_session_rows=""
all_client_rows=""
legacy_pane_rows=""
process_tree_loaded=false
sidebar_width_restored=false
declare -A legacy_contexts=()
declare -A process_parents=()
declare -A process_commands=()
declare -A pr_request_keys=()
declare -A pr_request_times=()
declare -A pr_request_panes=()
declare -A session_sources=()
declare -A session_source_panes=()
declare -A session_pane_rows=()
declare -A pane_rows_by_id=()
declare -A pane_ids_by_pid=()
declare -A pane_session_ids=()
declare -A editor_panes_by_path=()
declare -A session_client_pids=()
declare -A pane_pr_states=()
declare -A pane_pr_titles=()
declare -A pane_pr_urls=()
declare -A repository_sync_revisions=()
declare -A cached_repository_sync_statuses=()

run_tmux_commands() {
  local argument
  local command_bytes=0
  local batch_bytes=0
  local LC_ALL=C
  local -a command_arguments=()
  local -a batch_arguments=()

  for argument in "$@" ';'; do
    if [[ "$argument" != ';' ]]; then
      command_arguments+=("$argument")
      command_bytes=$((command_bytes + ${#argument} + 1))
      continue
    fi
    ((${#command_arguments[@]} > 0)) || continue
    if (( batch_bytes + command_bytes + 2 > 12000 && batch_bytes > 0 )); then
      tmux "${batch_arguments[@]}" || return
      batch_arguments=()
      batch_bytes=0
    fi
    batch_arguments+=("${command_arguments[@]}" ';')
    batch_bytes=$((batch_bytes + command_bytes + 2))
    command_arguments=()
    command_bytes=0
  done
  ((${#batch_arguments[@]} == 0)) || tmux "${batch_arguments[@]}"
}

branch_sync_status() {
  local repository_path="$1"
  local head_commit="$2"
  local upstream_commit="$3"
  local divergence
  local commits_ahead
  local commits_behind

  divergence="$(git -C "$repository_path" rev-list --left-right --count "${head_commit}...${upstream_commit}" 2>/dev/null)" || return 1
  read -r commits_ahead commits_behind <<< "$divergence"
  if (( commits_ahead > 0 || commits_behind > 0 )); then printf ' '; fi
  if (( commits_ahead > 0 )); then printf '↑'; fi
  if (( commits_behind > 0 )); then printf '↓'; fi
}

refresh_pull_request() {
  local pane_id="$1"
  local pane_path="$2"
  local pane_branch="$3"
  local remote_name
  local remote_url
  local remote_owner
  local merge_ref
  local head_branch
  local repository_metadata
  local repository_name
  local default_branch
  local pull_request
  local pull_request_state=""
  local pull_request_title=""
  local pull_request_url=""
  local current_path
  local current_branch
  local pane_rows
  local -A target_panes=()
  local -A validated_paths=()
  local -a pull_request_commands=()

  target_panes[$pane_id]="$pane_path"
  shift 3
  while (($# >= 2)); do
    target_panes[$1]="$2"
    shift 2
  done

  cd -- "$pane_path" || return
  repository_metadata="$(gtimeout 15 gh repo view --json nameWithOwner,defaultBranchRef \
    --jq '[.nameWithOwner, .defaultBranchRef.name] | @tsv' 2>/dev/null)" || return
  IFS=$'\t' read -r repository_name default_branch <<< "$repository_metadata"

  remote_name="$(git config --get "branch.${pane_branch}.remote" || printf origin)"
  [[ "$remote_name" != . ]] || remote_name=origin
  remote_url="$(git ls-remote --get-url "$remote_name" 2>/dev/null)" || return
  remote_owner="${remote_url%/*}"
  remote_owner="${remote_owner##*[:/]}"
  [[ "$remote_owner" =~ ^[a-zA-Z0-9_.-]+$ ]] || return
  head_branch="$pane_branch"
  merge_ref="$(git config --get "branch.${pane_branch}.merge" || true)"
  [[ "$merge_ref" != refs/heads/* ]] || head_branch="${merge_ref#refs/heads/}"

  pull_request=""
  if [[ "$head_branch" != "$default_branch" || "$remote_owner" != "${repository_name%%/*}" ]]; then
    pull_request="$(gtimeout 15 gh api --method GET "repos/${repository_name}/pulls" \
      -f state=all -f "head=${remote_owner}:${head_branch}" -f per_page=100 \
      -f sort=updated -f direction=desc --jq '
        (map(select(.state == "open")) + .) | .[0] // empty |
        [
          (if .merged_at != null then "merged" elif .state == "open" then "open" else "closed" end),
          (.title | gsub("[[:cntrl:]]"; " ")),
          .html_url
        ] | .[]
      ' 2>/dev/null)" || return
  fi

  current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" || return
  [[ "$current_branch" == "$pane_branch" ]] || return
  validated_paths[$pane_path]=1

  if [[ -n "$pull_request" ]]; then
    pull_request_state="${pull_request%%$'\n'*}"
    pull_request="${pull_request#*$'\n'}"
    pull_request_title="${pull_request%%$'\n'*}"
    pull_request_url="${pull_request#*$'\n'}"
    case "$pull_request_state" in open|merged|closed) ;; *) return ;; esac
  fi
  pane_rows="$(tmux list-panes -a -F "#{pane_id}${field_separator}#{pane_current_path}" 2>/dev/null)" || return
  while IFS="$field_separator" read -r pane_id current_path; do
    [[ -n "$pane_id" && -n "${target_panes[$pane_id]:-}" ]] || continue
    [[ "$current_path" == "${target_panes[$pane_id]}" ]] || continue
    if [[ ! -v validated_paths[$current_path] ]]; then
      current_branch="$(git -C "$current_path" symbolic-ref --quiet --short HEAD 2>/dev/null)" || continue
      [[ "$current_branch" == "$pane_branch" ]] || continue
      validated_paths[$current_path]=1
    fi
    pull_request_commands+=(set-option -p -t "$pane_id" @sidebar_pr_state "$pull_request_state" ';'
      set-option -p -t "$pane_id" @sidebar_pr_title "$pull_request_title" ';'
      set-option -p -t "$pane_id" @sidebar_pr_url "$pull_request_url" ';')
  done <<< "$pane_rows"
  run_tmux_commands "${pull_request_commands[@]}"
}

open_pull_request() {
  local target="$1"
  local pane_id
  local pull_request_url

  [[ "$target" =~ ^prpane[0-9]+$ ]] || return
  pane_id="%${target#prpane}"
  pull_request_url="$(tmux show-options -pqv -t "$pane_id" @sidebar_pr_url)" || return
  [[ "$pull_request_url" =~ ^https://[^/]+/[^/]+/[^/]+/pull/[0-9]+$ ]] || return
  open "$pull_request_url"
}

schedule_pull_request_refresh() {
  local request_key="$1"
  local pane_branch="$2"
  local pane_id
  local source_pane_id=""
  local previous_source_pane_id="${pr_request_panes[$request_key]:-}"
  local request_state=""
  local request_title=""
  local request_url=""
  shift 2

  for pane_id in "$@"; do
    if [[ "$pane_id" == "$previous_source_pane_id" && "${pr_request_keys[$pane_id]:-}" == "$request_key" ]]; then
      source_pane_id="$pane_id"
      break
    fi
  done
  if [[ -z "$source_pane_id" ]]; then
    for pane_id in "$@"; do
      [[ "${pr_request_keys[$pane_id]:-}" == "$request_key" ]] || continue
      source_pane_id="$pane_id"
      break
    done
  fi
  if [[ -n "$source_pane_id" ]]; then
    request_state="${pane_pr_states[$source_pane_id]}"
    request_title="${pane_pr_titles[$source_pane_id]}"
    request_url="${pane_pr_urls[$source_pane_id]}"
  fi
  for pane_id in "$@"; do
    if [[ "${pane_pr_states[$pane_id]}" != "$request_state" ||
          "${pane_pr_titles[$pane_id]}" != "$request_title" ||
          "${pane_pr_urls[$pane_id]}" != "$request_url" ]]; then
      session_status_commands+=(set-option -p -t "$pane_id" @sidebar_pr_state "$request_state" ';'
        set-option -p -t "$pane_id" @sidebar_pr_title "$request_title" ';'
        set-option -p -t "$pane_id" @sidebar_pr_url "$request_url" ';')
    fi
    pr_request_keys[$pane_id]="$request_key"
  done
  [[ -n "$pane_branch" ]] || return 0
  if [[ -n "$source_pane_id" && "$source_pane_id" == "$previous_source_pane_id" && -v pr_request_times[$request_key] ]]; then
    (( SECONDS - ${pr_request_times[$request_key]} >= 60 )) || return 0
  fi
  pr_request_panes[$request_key]="${source_pane_id:-$1}"
  pr_request_times[$request_key]="$SECONDS"
  pull_request_jobs+=("$request_key")
}

update_repository_status() {
  local pane_id="$1"
  local pane_path="$2"
  local previous_branch="$3"
  local previous_branch_sync="$4"
  local pane_branch
  local pane_branch_sync
  local repository_metadata
  local repository_root
  local repository_common_path
  local sync_revisions=""
  local reuse_sync_status=false
  local request_key
  local -a repository_fields=()

  if [[ ! -v repository_branches[$pane_path] ]]; then
    if repository_metadata="$(git -C "$pane_path" rev-parse --show-toplevel --path-format=absolute --git-common-dir \
      --is-shallow-repository HEAD '@{upstream}' --glob='refs/replace/*' \
      --symbolic-full-name --glob='refs/replace/*' --abbrev-ref HEAD 2>/dev/null)"; then
      mapfile -t repository_fields <<< "$repository_metadata"
      # Shallow boundaries and grafts can change ancestry without moving either branch.
      if [[ "${repository_fields[2]}" == false && ! -s "${repository_fields[1]}/info/grafts" ]]; then
        reuse_sync_status=true
      fi
      sync_revisions="${reuse_sync_status}:${repository_metadata}"
      pane_branch="${repository_fields[-1]}"
      [[ "$pane_branch" != HEAD ]] || pane_branch=""
    else
      mapfile -t repository_fields <<< "$repository_metadata"
      pane_branch="$(git -C "$pane_path" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
      if ((${#repository_fields[@]} < 2)); then
        repository_fields=("$pane_path" "$pane_path")
        if [[ -n "$pane_branch" ]]; then
          repository_fields[1]="$(git -C "$pane_path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || printf '%s' "$pane_path")"
        else
          repository_sync_statuses[$pane_path]=""
        fi
      fi
    fi
    repository_root="${repository_fields[0]:-$pane_path}"
    repository_common_path="${repository_fields[1]:-$pane_path}"
    repository_branches[$pane_path]="$pane_branch"
    repository_roots[$pane_path]="$repository_root"
    repository_common_paths[$pane_path]="$repository_common_path"
    if [[ ! -v repository_sync_statuses[$repository_root] ]]; then
      pane_branch_sync=""
      if [[ -n "$sync_revisions" ]]; then
        if [[ "$reuse_sync_status" == true && "${repository_sync_revisions[$repository_root]:-}" == "$sync_revisions" ]]; then
          pane_branch_sync="${cached_repository_sync_statuses[$repository_root]}"
        elif pane_branch_sync="$(branch_sync_status "$pane_path" "${repository_fields[3]}" "${repository_fields[4]}")"; then
          repository_sync_revisions[$repository_root]="$sync_revisions"
          cached_repository_sync_statuses[$repository_root]="$pane_branch_sync"
        fi
      fi
      repository_sync_statuses[$repository_root]="$pane_branch_sync"
    fi
  fi
  pane_branch="${repository_branches[$pane_path]}"
  pane_branch_sync="${repository_sync_statuses[${repository_roots[$pane_path]}]}"
  if [[ "$pane_branch" != "$previous_branch" ]]; then
    session_status_commands+=(set-option -p -t "$pane_id" @sidebar_branch "$pane_branch" ';')
  fi
  if [[ "$pane_branch_sync" != "$previous_branch_sync" ]]; then
    session_status_commands+=(set-option -p -t "$pane_id" @sidebar_branch_sync "$pane_branch_sync" ';')
  fi
  request_key="${repository_common_paths[$pane_path]}${field_separator}${pane_branch}"
  repository_panes[$request_key]+="${repository_panes[$request_key]:+ }${pane_id}"
  repository_request_branches[$request_key]="$pane_branch"
}

is_versioned_claude_process() {
  local command_name="$1"
  local pane_process_id="${2:-}"
  local process_pid
  local parent_pid

  [[ "$command_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+].*)?$ && "$pane_process_id" =~ ^[0-9]+$ ]] || return 1
  load_process_tree
  for process_pid in "${!process_commands[@]}"; do
    [[ "${process_commands[$process_pid]}" == */claude/versions/"$command_name" ]] || continue
    while [[ "$process_pid" =~ ^[0-9]+$ ]] && (( process_pid > 1 )); do
      [[ "$process_pid" == "$pane_process_id" ]] && return 0
      parent_pid="${process_parents[$process_pid]:-}"
      [[ -n "$parent_pid" && "$parent_pid" != "$process_pid" ]] || break
      process_pid="$parent_pid"
    done
  done
  return 1
}

agent_for_command() {
  local command_name="${1##*/}"

  case "$command_name" in
    codex*) agent_name=codex; agent_icon="" ;;
    claude*) agent_name=claude; agent_icon="" ;;
    fx*) agent_name=fx; agent_icon="" ;;
    pi|pi-*) agent_name=pi; agent_icon="π" ;;
    *)
      is_versioned_claude_process "$command_name" "${2:-}" || return 1
      agent_name=claude
      agent_icon=""
      ;;
  esac
}

detect_agent_state() {
  local current_agent_name="$1"
  local pane_title="$2"

  detected_state=idle

  case "$current_agent_name" in
    codex)
      [[ "$pane_title" == *"Action Required"* ]] && { detected_state=blocked; return; }
      [[ "$pane_title" =~ (^|[[:space:]])[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]([[:space:]]|$) ]] && { detected_state=working; return; }
      ;;
    claude)
      [[ "$pane_title" =~ ^[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏][[:space:]] ]] && { detected_state=working; return; }
      ;;
  esac
  return 0
}

render_agent() {
  local state="$1"
  local pane_id="$2"
  local icon="$3"
  local icon_gap="  "
  local color
  local label

  case "$state" in
    blocked) color="#ed8796"; label=action ;;
    working) color="#eed49f"; label=Working ;;
    *) color="#a6da95"; label=Idle ;;
  esac

  [[ "$icon" != π ]] || icon_gap=" "
  printf -v rendered_agent '#[fg=%s,range=user|agent%s]%s%s%-7s#[norange] ' "$color" "${pane_id#%}" "$icon" "$icon_gap" "$label"
}

clean_agent_title() {
  cleaned_agent_title="${1//[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]/}"
  cleaned_agent_title="${cleaned_agent_title//$'\t'/ }"
  cleaned_agent_title="${cleaned_agent_title//$'\r'/ }"
  cleaned_agent_title="${cleaned_agent_title//$'\n'/ }"
  cleaned_agent_title="${cleaned_agent_title#"${cleaned_agent_title%%[![:space:]]*}"}"
  if [[ "${2:-}" == codex && "$cleaned_agent_title" == '● '* ]]; then
    cleaned_agent_title="${cleaned_agent_title#●}"
    cleaned_agent_title="${cleaned_agent_title#"${cleaned_agent_title%%[![:space:]]*}"}"
  fi
  cleaned_agent_title="${cleaned_agent_title%"${cleaned_agent_title##*[![:space:]]}"}"
}

restore_sidebar_width() {
  local current_width
  local base_width
  local previous_width
  previous_width="$(tmux show-options -gqv @sidebar_auto_width)"
  [[ "$previous_width" =~ ^[0-9]+$ ]] || return 0
  current_width="$(tmux show-options -gqv side-status-width)"
  base_width="$(tmux show-options -gqv @sidebar_base_width)"
  if [[ "$base_width" =~ ^[0-9]+$ && "$current_width" == "$previous_width" ]]; then
    tmux set-option -g side-status-width "$base_width"
  fi
  tmux set-option -guq @sidebar_base_width \; set-option -guq @sidebar_auto_width
}

load_process_tree() {
  local process_pid
  local parent_pid
  local process_command
  local process_rows

  [[ "$process_tree_loaded" == true ]] && return
  process_rows="$(ps -axo pid=,ppid=,comm= 2>/dev/null || true)"
  while read -r process_pid parent_pid process_command; do
    [[ -n "$process_pid" ]] || continue
    process_parents[$process_pid]="$parent_pid"
    process_commands[$process_pid]="$process_command"
  done <<< "$process_rows"
  process_tree_loaded=true
}

resolve_source_session() {
  local agent_session_id="$1"
  local agent_session_name="$2"
  local agent_path="$3"
  local candidate_pane_id
  local candidate_session_id
  local client_pid
  local process_pid
  local parent_pid
  local matching_pane_count=0
  local matching_pane_id=""

  resolved_source_session_id="$agent_session_id"
  resolved_source_pane_id=""
  if [[ ${#agent_session_name} -ne 17 || ! "$agent_session_name" =~ ^[^[:space:]]+[[:space:]][[:xdigit:]]+$ ]]; then
    return
  fi

  load_process_tree
  for client_pid in ${session_client_pids[$agent_session_id]:-}; do
    process_pid="$client_pid"
    while [[ "$process_pid" =~ ^[0-9]+$ ]] && (( process_pid > 1 )); do
      for candidate_pane_id in ${pane_ids_by_pid[$process_pid]:-}; do
        candidate_session_id="${pane_session_ids[$candidate_pane_id]}"
        if [[ "$candidate_session_id" != "$agent_session_id" ]]; then
          resolved_source_session_id="$candidate_session_id"
          resolved_source_pane_id="$candidate_pane_id"
          return
        fi
      done

      parent_pid="${process_parents[$process_pid]:-}"
      [[ -z "$parent_pid" || "$parent_pid" == "$process_pid" ]] && break
      process_pid="$parent_pid"
    done
  done

  for candidate_pane_id in ${editor_panes_by_path[$agent_path]:-}; do
    [[ "${pane_session_ids[$candidate_pane_id]}" != "$agent_session_id" ]] || continue
    matching_pane_count=$((matching_pane_count + 1))
    matching_pane_id="$candidate_pane_id"
  done
  if (( matching_pane_count == 1 )); then
    resolved_source_session_id="${pane_session_ids[$matching_pane_id]}"
    resolved_source_pane_id="$matching_pane_id"
  fi
}

resolve_session_sources() {
  local row_type
  local session_id
  local session_name
  local _previous_state
  local session_path
  local _remaining_fields

  session_sources=()
  session_source_panes=()
  while IFS="$field_separator" read -r row_type session_id session_name _previous_state session_path _remaining_fields; do
    [[ -n "$session_id" ]] || continue
    resolve_source_session "$session_id" "$session_name" "$session_path"
    session_sources[$session_id]="$resolved_source_session_id"
    session_source_panes[$session_id]="$resolved_source_pane_id"
  done <<< "$all_session_rows"
}

load_snapshot() {
  local snapshot
  local row_type
  local row
  local reading_environment=true
  local session_id
  local pane_id
  local pane_command
  local pane_path
  local pane_pid
  local pane_pr_state
  local pane_pr_title
  local pane_pr_url
  local remaining_fields
  local client_pid

  snapshot="$(tmux show-environment -g \
    \; display-message -p "$environment_marker" \
    \; list-panes -a -F "P${field_separator}#{session_id}${field_separator}#{session_name}${field_separator}#{pane_id}${field_separator}#{pane_current_command}${field_separator}#{pane_current_path}${field_separator}#{pane_pid}${field_separator}#{pane_title}${field_separator}#{@sidebar_agent_state}${field_separator}#{@sidebar_agent_icon}${field_separator}#{@sidebar_agent_title}${field_separator}#{@sidebar_branch}${field_separator}#{@sidebar_branch_sync}${field_separator}#{@sidebar_pr_state}${field_separator}#{@sidebar_pr_title}${field_separator}#{@sidebar_pr_url}" \
    \; list-sessions -F "S${field_separator}#{session_id}${field_separator}#{session_name}${field_separator}#{@sidebar_agents}${field_separator}#{session_path}${field_separator}#{@sidebar_agent_panes}${field_separator}#{@sidebar_source_session}${field_separator}#{pane_id}${field_separator}#{@sidebar_agent_groups}${field_separator}#{@sidebar_source_pane}" \
    \; list-clients -F "C${field_separator}#{session_id}${field_separator}#{client_pid}" \
    \; list-panes -a -f '#{!=:#{@status_context_managed},1}' -F "L${field_separator}#{pane_id}" 2>/dev/null)" || return 1

  all_environment_rows=""
  all_pane_rows=""
  all_session_rows=""
  all_client_rows=""
  legacy_pane_rows=""
  pane_rows_by_id=()
  pane_ids_by_pid=()
  pane_session_ids=()
  editor_panes_by_path=()
  session_client_pids=()
  pane_pr_states=()
  pane_pr_titles=()
  pane_pr_urls=()
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
      P)
        all_pane_rows+="${row}"$'\n'
        IFS="$field_separator" read -r row_type session_id remaining_fields pane_id pane_command pane_path pane_pid remaining_fields remaining_fields remaining_fields remaining_fields remaining_fields remaining_fields pane_pr_state pane_pr_title pane_pr_url <<< "$row"
        pane_rows_by_id[$pane_id]="$row"
        pane_ids_by_pid[$pane_pid]+="${pane_ids_by_pid[$pane_pid]:+ }${pane_id}"
        pane_session_ids[$pane_id]="$session_id"
        pane_pr_states[$pane_id]="$pane_pr_state"
        pane_pr_titles[$pane_id]="$pane_pr_title"
        pane_pr_urls[$pane_id]="$pane_pr_url"
        if [[ "$pane_command" == nvim* ]]; then
          editor_panes_by_path[$pane_path]+="${editor_panes_by_path[$pane_path]:+ }${pane_id}"
        fi
        ;;
      S) all_session_rows+="${row}"$'\n' ;;
      C)
        all_client_rows+="${row}"$'\n'
        IFS="$field_separator" read -r row_type session_id client_pid <<< "$row"
        session_client_pids[$session_id]+="${session_client_pids[$session_id]:+ }${client_pid}"
        ;;
      L) legacy_pane_rows+="${row}"$'\n' ;;
    esac
  done <<< "$snapshot"
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
  local session_agents
  local session_panes
  local session_agent_groups
  local session_unread
  local previous_agent_groups
  local group_path
  local group_panes
  local previous_agents
  local previous_panes
  local previous_agent_state
  local previous_agent_icon
  local previous_agent_title
  local previous_source_session_id
  local previous_source_pane_id
  local source_session_id
  local session_current_path
  local session_active_pane_id
  local previous_branch
  local previous_branch_sync
  local remaining_fields
  local pane_row
  local request_key
  local repository_root
  local -A pane_paths=()
  local -A repository_branches=()
  local -A repository_roots=()
  local -A repository_common_paths=()
  local -A repository_sync_statuses=()
  local -A repository_panes=()
  local -A repository_request_branches=()
  local -a request_panes=()
  local -a pull_request_jobs=()
  local -a request_arguments=()
  local -A rendered_panes=()
  local -A directory_panes=()
  local -a group_paths=()
  local -a session_status_commands=()

  load_snapshot || return 1
  update_legacy_contexts
  process_tree_loaded=false
  process_parents=()
  process_commands=()
  resolve_session_sources
  session_pane_rows=()
  while IFS= read -r pane_row; do
    [[ -n "$pane_row" ]] || continue
    pane_session_id="${pane_row#*"$field_separator"}"
    pane_session_id="${pane_session_id%%"$field_separator"*}"
    source_session_id="${session_sources[$pane_session_id]:-$pane_session_id}"
    session_pane_rows[$source_session_id]+="$pane_row"$'\n'
  done <<< "$all_pane_rows"
  rendered_status=""

  while IFS="$field_separator" read -r row_type session_id session_name previous_agents session_current_path previous_panes previous_source_session_id session_active_pane_id previous_agent_groups previous_source_pane_id; do
    [[ -n "$session_id" ]] || continue
    session_agents=""
    session_panes=""
    session_agent_groups=""
    session_unread=false
    rendered_panes=()
    directory_panes=()
    group_paths=()
    source_session_id="${session_sources[$session_id]}"
    [[ "$source_session_id" != "$session_id" ]] || source_session_id=""
    if [[ "$source_session_id" != "$previous_source_session_id" ]]; then
      session_status_commands+=(set-option -t "$session_id" @sidebar_source_session "$source_session_id" ';')
    fi
    if [[ "${session_source_panes[$session_id]}" != "$previous_source_pane_id" ]]; then
      session_status_commands+=(set-option -t "$session_id" @sidebar_source_pane "${session_source_panes[$session_id]}" ';')
    fi
    while IFS="$field_separator" read -r row_type pane_session_id _pane_session_name pane_id pane_command pane_path _pane_pid pane_title previous_agent_state previous_agent_icon previous_agent_title previous_branch previous_branch_sync remaining_fields; do
      [[ -n "$pane_session_id" ]] || continue
      [[ "${session_sources[$pane_session_id]:-$pane_session_id}" == "$session_id" ]] || continue
      [[ -z "${rendered_panes[$pane_id]:-}" ]] || continue
      agent_for_command "$pane_command" "$_pane_pid" || continue
      pane_paths[$pane_id]="$pane_path"
      detect_agent_state "$agent_name" "$pane_title"
      if [[ "$previous_agent_state" == working && "$detected_state" == idle ]]; then
        session_unread=true
      fi
      clean_agent_title "$pane_title" "$agent_name"
      if [[ "$detected_state" != "$previous_agent_state" ]]; then
        session_status_commands+=(set-option -p -t "$pane_id" @sidebar_agent_state "$detected_state" ';')
      fi
      if [[ "$agent_icon" != "$previous_agent_icon" ]]; then
        session_status_commands+=(set-option -p -t "$pane_id" @sidebar_agent_icon "$agent_icon" ';')
      fi
      if [[ "$cleaned_agent_title" != "$previous_agent_title" ]]; then
        session_status_commands+=(set-option -p -t "$pane_id" @sidebar_agent_title "$cleaned_agent_title" ';')
      fi
      update_repository_status "$pane_id" "$pane_path" "$previous_branch" "$previous_branch_sync"
      render_agent "$detected_state" "${session_source_panes[$pane_session_id]:-$pane_id}" "$agent_icon"
      session_agents+="$rendered_agent"
      session_panes+="${session_panes:+ }${pane_id}"
      group_panes="${directory_panes[$pane_path]:-}"
      [[ -n "$group_panes" ]] || group_paths+=("$pane_path")
      directory_panes[$pane_path]="${group_panes:+${group_panes},}${pane_id}"
      rendered_panes[$pane_id]=1
    done <<< "${session_pane_rows[$session_id]:-}"

    for group_path in "${group_paths[@]}"; do
      session_agent_groups+="${session_agent_groups:+ }${directory_panes[$group_path]}"
    done

    if [[ -z "$session_panes" && -z "$source_session_id" ]]; then
      pane_row="${pane_rows_by_id[$session_active_pane_id]:-}"
      if [[ -n "$pane_row" ]]; then
        IFS="$field_separator" read -r row_type pane_session_id _pane_session_name pane_id pane_command pane_path _pane_pid pane_title previous_agent_state previous_agent_icon previous_agent_title previous_branch previous_branch_sync remaining_fields <<< "$pane_row"
        pane_paths[$pane_id]="$pane_path"
        update_repository_status "$pane_id" "$pane_path" "$previous_branch" "$previous_branch_sync"
      fi
    fi

    if [[ "$session_agents" != "$previous_agents" ]]; then
      session_status_commands+=(set-option -t "$session_id" @sidebar_agents "$session_agents" ';')
    fi
    if [[ "$session_panes" != "$previous_panes" ]]; then
      session_status_commands+=(set-option -t "$session_id" @sidebar_agent_panes "$session_panes" ';')
    fi
    if [[ "$session_agent_groups" != "$previous_agent_groups" ]]; then
      session_status_commands+=(set-option -t "$session_id" @sidebar_agent_groups "$session_agent_groups" ';')
    fi
    if [[ "$session_unread" == true ]]; then
      session_status_commands+=(if-shell -F -t "$session_id" '#{session_attached}'
        "set-option -t '$session_id' @sidebar_unread 0"
        "set-option -t '$session_id' @sidebar_unread 1" ';')
    fi

    if [[ -n "$session_agents" ]]; then
      rendered_status+="#[norange,fg=#a4adca,bold]   ${session_name//#/##} ${session_agents}"
    fi
  done <<< "$all_session_rows"

  for request_key in "${!repository_panes[@]}"; do
    read -r -a request_panes <<< "${repository_panes[$request_key]}"
    schedule_pull_request_refresh "$request_key" "${repository_request_branches[$request_key]}" "${request_panes[@]}"
  done
  for repository_root in "${!repository_sync_revisions[@]}"; do
    if [[ ! -v repository_sync_statuses[$repository_root] ]]; then
      unset 'repository_sync_revisions[$repository_root]' 'cached_repository_sync_statuses[$repository_root]'
    fi
  done
  for pane_id in "${!pr_request_keys[@]}"; do
    [[ -v pane_paths[$pane_id] ]] || unset 'pr_request_keys[$pane_id]'
  done
  for request_key in "${!pr_request_times[@]}"; do
    if [[ ! -v repository_panes[$request_key] ]]; then
      unset 'pr_request_times[$request_key]' 'pr_request_panes[$request_key]'
    fi
  done
  if ((${#session_status_commands[@]} > 0)); then
    if ! run_tmux_commands "${session_status_commands[@]}" 2>/dev/null; then
      pr_request_keys=()
      pr_request_times=()
      pr_request_panes=()
      return 1
    fi
  fi
  if [[ "$sidebar_width_restored" == false ]]; then
    restore_sidebar_width
    sidebar_width_restored=true
  fi
  for request_key in "${pull_request_jobs[@]}"; do
    read -r -a request_panes <<< "${repository_panes[$request_key]}"
    pane_id="${request_panes[0]}"
    request_arguments=(--pr "$pane_id" "${pane_paths[$pane_id]}" "${repository_request_branches[$request_key]}")
    for pane_id in "${request_panes[@]:1}"; do
      request_arguments+=("$pane_id" "${pane_paths[$pane_id]}")
    done
    bash "${BASH_SOURCE[0]}" "${request_arguments[@]}" >/dev/null 2>&1 &
  done
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
  run_tmux_commands "${tmux_commands[@]}" 2>/dev/null
}

clear_watcher_pid() {
  if [[ "$(tmux show-option -gqv @agent-status-watcher-pid 2>/dev/null)" == "$$" ]]; then
    tmux set-option -guq @agent-status-watcher-pid 2>/dev/null || true
  fi
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
  trap clear_watcher_pid EXIT

  timer_pipe="/tmp/tmux-agent-status-${$}.pipe"
  mkfifo "$timer_pipe"
  exec 9<> "$timer_pipe"
  rm -f "$timer_pipe"

  while [[ "$(tmux show-option -gqv @agent-status-watcher-pid 2>/dev/null)" == "$$" ]]; do
    if ! build_agent_status; then
      tmux has-session 2>/dev/null || break
      read -r -t 1 -u 9 _ || true
      continue
    fi
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
    --open-pr)
      open_pull_request "$2"
      ;;
    --pr)
      refresh_pull_request "${@:2}"
      ;;
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
