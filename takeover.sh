#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <claude|codex> [-f|--force]" >&2
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

FORCE=0
[[ "${1:-}" == "-f" || "${1:-}" == "--force" ]] && FORCE=1

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
    ps -o pid,tty,command -p "$(IFS=,; echo "${pids[*]}")"
    exit 1
    ;;
esac

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
