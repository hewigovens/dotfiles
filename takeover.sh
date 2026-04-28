#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <claude|codex> [--pid PID] [-f|--force]" >&2
  exit 2
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
        | awk '$2=="codex" && !($4 ~ /^(app-server|exec|review|login|logout|mcp|plugin|mcp-server|app|completion|sandbox|debug|apply|cloud|exec-server|features|help)$/) {print $1}'
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

  cd "$cwd"
  exec claude --continue
}

restart_codex() {
  local cwd=$1
  local port="${CODEX_REMOTE_PORT:-8765}"
  local remote="ws://127.0.0.1:$port"

  if lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "app-server already listening on :$port, reusing"
  else
    nohup codex app-server --listen "$remote" >/tmp/codex-app-server.log 2>&1 &
    disown
    for _ in $(seq 1 50); do
      lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 && break
      sleep 0.1
    done
    echo "app-server: $remote (log: /tmp/codex-app-server.log)"
  fi

  cd "$cwd"
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
    *)
      usage
      ;;
  esac
done

if [[ -n "$PID" && ! "$PID" =~ ^[0-9]+$ ]]; then
  echo "invalid pid: $PID" >&2
  exit 2
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
