#!/usr/bin/env bash
set -euo pipefail

usage() {
  local name
  name=$(basename "$0")

  cat >&2 <<EOF
usage: $name <claude|codex> [--pid PID] [-f|--force] [--ssh HOST] [--remote-control [NAME]]

examples:
  $name codex
  $name codex --pid 12345
  $name codex --ssh std
  $name codex --ssh std --pid 12345
  $name codex --remote-control
  CODEX_APP_SERVER_HOST=192.168.50.124 $name codex --ssh std
  $name claude
  $name claude --remote-control
  $name claude --remote-control my-session

notes:
  --ssh is codex-only; it starts a remote codex app-server and attaches locally.
  claude takeover restarts claude interactively on the current machine.
  claude --remote-control requires a Claude Code build/account that supports it.
  codex --remote-control starts codex remote-control only; it does not attach a local TUI.

environment:
  CODEX_REMOTE_PORT           app-server port (default: 8765)
  CODEX_APP_SERVER_HOST       bind host for codex app-server
  CODEX_APP_SERVER_REMOTE     client websocket URL override
  CODEX_TAKEOVER_CODEX_MODE   app-server (default) or remote-control
EOF
  exit 2
}

shell_quote() {
  printf '%q' "$1"
}

get_cwd() {
  local pid=$1
  local cwd

  cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | awk '/^n/{print substr($0,2); exit}')
  printf '%s\n' "${cwd:-$HOME}"
}

collect_pids() {
  local tool=$1

  case "$tool" in
    claude)
      ps -axo pid=,comm=,command= \
        | awk '$2=="claude" && !($4 ~ /^--?(mcp|doctor|update|migrate-installer)$/) {print $1}'
      ;;
    codex)
      ps -axo pid=,comm=,command= \
        | awk '$2=="codex" && !($4 ~ /^(app-server|remote-control|exec|review|login|logout|mcp|plugin|mcp-server|app|completion|sandbox|debug|apply|cloud|exec-server|features|help)$/) {print $1}'
      ;;
    *)
      usage
      ;;
  esac
}

pid_matches_tool() {
  local tool=$1
  local wanted_pid=$2

  while IFS= read -r found_pid; do
    [[ "$found_pid" == "$wanted_pid" ]] && return 0
  done < <(collect_pids "$tool")

  return 1
}

print_tuis() {
  local pid tty cpu cwd command

  printf '%6s %-8s %-5s %-50s %s\n' "PID" "TTY" "CPU" "CWD" "COMMAND"
  for pid in "$@"; do
    tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ' || true)
    cpu=$(ps -o %cpu= -p "$pid" 2>/dev/null | awk '{print int($1)}' || true)
    cwd=$(get_cwd "$pid")
    command=$(ps -o command= -p "$pid" 2>/dev/null || true)

    printf '%6s %-8s %4s%% %-50s %s\n' \
      "$pid" "${tty:-?}" "${cpu:-?}" "$cwd" "${command:-?}"
  done
}

restart_claude() {
  local cwd=$1
  local args=(--continue)

  cd "$cwd"
  if [[ "${TAKEOVER_REMOTE_CONTROL:-0}" == "1" ]]; then
    if ! claude --help 2>&1 | grep -q -- '--remote-control'; then
      echo "this claude build does not support --remote-control" >&2
      exit 1
    fi

    args+=(--remote-control)
    [[ -n "${TAKEOVER_REMOTE_CONTROL_NAME:-}" ]] && args+=("$TAKEOVER_REMOTE_CONTROL_NAME")
  fi

  exec claude "${args[@]}"
}

restart_codex() {
  local cwd=$1
  local mode="${CODEX_TAKEOVER_CODEX_MODE:-app-server}"

  if [[ "${TAKEOVER_REMOTE_CONTROL:-0}" == "1" ]]; then
    mode=remote-control
  fi

  case "$mode" in
    app-server|app_server|tui|websocket)
      restart_codex_app_server "$cwd"
      ;;
    remote-control|remote_control)
      if ! codex remote-control --help >/dev/null 2>&1; then
        echo "codex remote-control unavailable, falling back to websocket TUI" >&2
        restart_codex_app_server "$cwd"
        return
      fi

      cd "$cwd"
      echo "starting codex remote-control from $cwd"
      exec codex remote-control
      ;;
    *)
      echo "invalid CODEX_TAKEOVER_CODEX_MODE: $mode" >&2
      exit 2
      ;;
  esac
}

restart_codex_app_server() {
  local cwd=$1
  local port="${CODEX_REMOTE_PORT:-8765}"
  local listen_host="${CODEX_APP_SERVER_HOST:-127.0.0.1}"
  local listen="ws://$listen_host:$port"
  local remote_host="$listen_host"
  [[ "$remote_host" == "0.0.0.0" ]] && remote_host="127.0.0.1"
  local remote="${CODEX_APP_SERVER_REMOTE:-ws://$remote_host:$port}"

  if lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 \
    && ! app_server_is_listening_with "$port" "$listen"; then
    restart_codex_app_server_listener "$port" "$listen"
  fi

  if app_server_is_listening_with "$port" "$listen"; then
    echo "app-server already listening on :$port, reusing"
  else
    nohup codex app-server --listen "$listen" </dev/null >/tmp/codex-app-server.log 2>&1 &
    disown
    for _ in $(seq 1 50); do
      lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 && break
      sleep 0.1
    done
    echo "app-server: $listen (log: /tmp/codex-app-server.log)"
  fi

  if [[ "${CODEX_TAKEOVER_SERVER_ONLY:-0}" == "1" ]]; then
    echo "TAKEOVER_REMOTE=$remote"
    echo "TAKEOVER_CWD=$cwd"
    return
  fi

  cd "$cwd"
  exec codex --remote "$remote" -C "$cwd" resume --last
}

app_server_is_listening_with() {
  local port=$1
  local listen=$2
  local pid command

  while IFS= read -r pid; do
    command=$(ps -o command= -p "$pid" 2>/dev/null || true)
    [[ "$command" == *"codex app-server"* && "$command" == *"--listen $listen"* ]] && return 0
  done < <(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)

  return 1
}

restart_codex_app_server_listener() {
  local port=$1
  local listen=$2
  local pids=()
  local pid command

  while IFS= read -r pid; do
    [[ -n "$pid" ]] && pids+=("$pid")
  done < <(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)

  for pid in "${pids[@]}"; do
    command=$(ps -o command= -p "$pid" 2>/dev/null || true)
    if [[ "$command" != *"codex app-server"* ]]; then
      echo "port $port is already in use by a non-codex listener:" >&2
      ps -o pid,comm,command -p "$pid" 2>/dev/null || true
      exit 1
    fi
  done

  echo "app-server already listening on :$port, rebinding to $listen"
  for pid in "${pids[@]}"; do
    kill -TERM "$pid" 2>/dev/null || true
  done
  for _ in $(seq 1 25); do
    lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 || break
    sleep 0.2
  done
  for pid in "${pids[@]}"; do
    kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" || true
  done
}

guess_ssh_app_server_host() {
  local ssh_host=$1

  ssh "$ssh_host" 'bash -lc '"'"'
    if command -v tailscale >/dev/null 2>&1; then
      addr=$(tailscale ip -4 2>/dev/null | sed -n "1p")
      [[ -n "$addr" ]] && { printf "%s\n" "$addr"; exit 0; }
    fi
    ipconfig getifaddr en0 2>/dev/null && exit 0
    ipconfig getifaddr en1 2>/dev/null && exit 0
    set -- $(hostname -I 2>/dev/null || true)
    [[ -n "${1:-}" ]] && printf "%s\n" "$1"
  '"'"'' | sed -n '1p'
}

takeover_over_ssh() {
  local ssh_host=$1
  local tool=$2
  local script=$3
  local listen_host="${CODEX_APP_SERVER_HOST:-}"
  local port="${CODEX_REMOTE_PORT:-8765}"
  local remote_args=()
  local remote_cmd remote_output remote cwd

  if [[ "$tool" != "codex" ]]; then
    echo "--ssh is only supported for codex" >&2
    exit 2
  fi
  if [[ "${TAKEOVER_REMOTE_CONTROL:-0}" == "1" ]]; then
    echo "--ssh cannot be combined with --remote-control" >&2
    exit 2
  fi
  if [[ ! -r "$script" ]]; then
    script=$(command -v "$script" || true)
  fi
  if [[ ! -r "$script" ]]; then
    echo "cannot read takeover script for SSH streaming" >&2
    exit 1
  fi

  if [[ -z "$listen_host" ]]; then
    listen_host=$(guess_ssh_app_server_host "$ssh_host")
  fi
  if [[ -z "$listen_host" ]]; then
    echo "could not determine a reachable address for $ssh_host" >&2
    echo "set CODEX_APP_SERVER_HOST to the remote Tailscale or LAN IP" >&2
    exit 1
  fi

  [[ "$FORCE" -eq 1 ]] && remote_args+=("--force")
  [[ -n "$PID" ]] && remote_args+=("--pid" "$PID")

  remote_cmd="env CODEX_APP_SERVER_HOST=$(shell_quote "$listen_host") CODEX_REMOTE_PORT=$(shell_quote "$port") CODEX_TAKEOVER_SERVER_ONLY=1 bash -s -- codex"
  for arg in "${remote_args[@]}"; do
    remote_cmd+=" $(shell_quote "$arg")"
  done

  if ! remote_output=$(ssh "$ssh_host" "$remote_cmd" < "$script" 2>&1); then
    printf '%s\n' "$remote_output"
    exit 1
  fi

  printf '%s\n' "$remote_output"
  remote=$(printf '%s\n' "$remote_output" | awk -F= '/^TAKEOVER_REMOTE=/{print substr($0,17)}' | tail -n 1)
  cwd=$(printf '%s\n' "$remote_output" | awk -F= '/^TAKEOVER_CWD=/{print substr($0,14)}' | tail -n 1)

  if [[ -z "$remote" || -z "$cwd" ]]; then
    echo "remote takeover did not report a Codex endpoint" >&2
    exit 1
  fi

  exec codex --remote "$remote" -C "$cwd" resume --last
}

tool=${1:-}
[[ -n "$tool" ]] || usage
shift

case "$tool" in
  claude|codex) ;;
  *) usage ;;
esac

FORCE=0
PID=
SSH_HOST=
TAKEOVER_REMOTE_CONTROL=0
TAKEOVER_REMOTE_CONTROL_NAME=

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force)
      FORCE=1
      shift
      ;;
    --pid)
      shift
      [[ -n "${1:-}" ]] || usage
      PID=$1
      shift
      ;;
    --pid=*)
      PID=${1#--pid=}
      [[ -n "$PID" ]] || usage
      shift
      ;;
    --ssh)
      shift
      [[ -n "${1:-}" ]] || usage
      SSH_HOST=$1
      shift
      ;;
    --ssh=*)
      SSH_HOST=${1#--ssh=}
      [[ -n "$SSH_HOST" ]] || usage
      shift
      ;;
    --remote-control)
      TAKEOVER_REMOTE_CONTROL=1
      shift
      if [[ -n "${1:-}" && "$1" != --* ]]; then
        TAKEOVER_REMOTE_CONTROL_NAME=$1
        shift
      fi
      ;;
    --remote-control=*)
      TAKEOVER_REMOTE_CONTROL=1
      TAKEOVER_REMOTE_CONTROL_NAME=${1#--remote-control=}
      shift
      ;;
    --server-only)
      CODEX_TAKEOVER_SERVER_ONLY=1
      export CODEX_TAKEOVER_SERVER_ONLY
      shift
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -n "$PID" && ! "$PID" =~ ^[0-9]+$ ]]; then
  echo "invalid pid: $PID" >&2
  exit 2
fi

if [[ "$tool" == "codex" && -n "$TAKEOVER_REMOTE_CONTROL_NAME" ]]; then
  echo "codex --remote-control does not accept a session name in this script" >&2
  exit 2
fi

if [[ -n "$SSH_HOST" ]]; then
  takeover_over_ssh "$SSH_HOST" "$tool" "$0"
fi

if [[ -n "$PID" ]]; then
  if ! kill -0 "$PID" 2>/dev/null; then
    echo "pid $PID is not running"
    exit 1
  fi

  if ! pid_matches_tool "$tool" "$PID"; then
    echo "pid $PID is not a running $tool TUI"
    ps -o pid,tty,comm,command -p "$PID" 2>/dev/null || true
    exit 1
  fi

  pid=$PID
else
  pids=()
  while IFS= read -r found_pid; do
    [[ -n "$found_pid" ]] && pids+=("$found_pid")
  done < <(collect_pids "$tool")

  case "${#pids[@]}" in
    0)
      echo "no running $tool TUI found"
      exit 1
      ;;
    1)
      pid=${pids[0]}
      ;;
    *)
      echo "multiple $tool TUIs running:"
      print_tuis "${pids[@]}"
      echo "rerun with --pid PID to choose one"
      exit 1
      ;;
  esac
fi

cpu=$(ps -o %cpu= -p "$pid" | awk '{print int($1)}')
cwd=$(get_cwd "$pid")
printf '%s TUI: pid=%s tty=%s cpu=%s%% cwd=%s\n' \
  "$tool" "$pid" "$(ps -o tty= -p "$pid" | tr -d ' ')" "$cpu" "$cwd"

if [[ "$cpu" -gt 10 && "$FORCE" -ne 1 ]]; then
  read -rp "looks active (likely mid-turn). kill anyway? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || exit 1
fi

kill -TERM "$pid" 2>/dev/null || true
for _ in $(seq 1 25); do
  kill -0 "$pid" 2>/dev/null || break
  sleep 0.2
done
kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" || true
echo "killed $pid"

case "$tool" in
  claude)
    restart_claude "$cwd"
    ;;
  codex)
    restart_codex "$cwd"
    ;;
esac
