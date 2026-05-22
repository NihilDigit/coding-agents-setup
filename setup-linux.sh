#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./setup-linux.sh [--agent prompt|codex|claude|both|none]

This script writes agent rule files and installs user-local Linux helpers. It does not install system packages or modify shell profiles.
USAGE
}

agent="prompt"
while (($#)); do
  case "$1" in
    --agent)
      agent="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$agent" in
  prompt|codex|claude|both|none) ;;
  *)
    echo "--agent must be one of: prompt, codex, claude, both, none" >&2
    exit 2
    ;;
esac

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

install_linux_helpers() {
  local bin_dir="$HOME/.local/bin"
  local clip_run="$bin_dir/clip-run"
  mkdir -p -- "$bin_dir"
  backup_file "$clip_run"
  install -m 0755 "$script_dir/scripts/clip-run" "$clip_run"
  echo "Installed $clip_run"
}

is_arch_like() {
  [[ -r /etc/os-release ]] || return 1
  local id="" id_like=""
  # shellcheck disable=SC1091
  source /etc/os-release
  id="${ID:-}"
  id_like="${ID_LIKE:-}"
  [[ " $id $id_like " == *" arch "* ]]
}

linux_rule_files() {
  local files=(AGENTS.shared.md AGENTS.linux.md)
  if is_arch_like; then
    files+=(AGENTS.linux-arch.md)
  fi
  printf '%s\n' "${files[@]}"
}

join_rules() {
  local first=1
  for file in "$@"; do
    if [[ ! -f "$script_dir/rules/$file" ]]; then
      echo "Missing rule file: rules/$file" >&2
      exit 1
    fi
    if [[ "$first" -eq 0 ]]; then
      printf '\n\n'
    fi
    sed -e '${/^$/d;}' "$script_dir/rules/$file"
    first=0
  done
  printf '\n'
}

backup_file() {
  local path="$1"
  if [[ -e "$path" ]]; then
    local backup="${path}.bak-$(date +%Y%m%d%H%M%S)"
    cp -a -- "$path" "$backup"
    echo "Backed up $path -> $backup"
  fi
}

write_codex() {
  local dir="$HOME/.codex"
  local path="$dir/AGENTS.md"
  mkdir -p -- "$dir"
  backup_file "$path"
  mapfile -t base_rules < <(linux_rule_files)
  join_rules "${base_rules[@]}" AGENTS.codex.md AGENTS.linux-initial-setup.md > "$path"
  echo "Wrote $path"
}

write_claude() {
  local dir="$HOME/.claude"
  local path="$dir/CLAUDE.md"
  mkdir -p -- "$dir"
  backup_file "$path"
  mapfile -t base_rules < <(linux_rule_files)
  join_rules "${base_rules[@]}" CLAUDE.md AGENTS.linux-initial-setup.md > "$path"
  echo "Wrote $path"
}

select_agent() {
  if [[ "$agent" != "prompt" ]]; then
    printf '%s\n' "$agent"
    return
  fi
  if [[ ! -t 0 ]]; then
    printf '%s\n' "both"
    return
  fi

  printf '%s\n' 'Which coding agent should be configured?'
  printf '%s\n' '  1. Codex'
  printf '%s\n' '  2. Claude Code'
  printf '%s\n' '  3. Both'
  printf '%s\n' '  4. Write no agent files'
  printf '%s' 'Select [1-4] (default: 3): '
  read -r answer
  case "$answer" in
    1) printf '%s\n' 'codex' ;;
    2) printf '%s\n' 'claude' ;;
    4) printf '%s\n' 'none' ;;
    *) printf '%s\n' 'both' ;;
  esac
}

target_agent="$(select_agent)"

case "$agent" in
  prompt) ;;
  *) target_agent="$agent" ;;
esac

case "$target_agent" in
  codex) write_codex ;;
  claude) write_claude ;;
  both) write_codex; write_claude ;;
  none) echo "No agent rule files written." ;;
esac

install_linux_helpers
