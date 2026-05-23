#!/usr/bin/env bash
set -u

failures=0
warnings=0

ok() {
  printf 'ok: %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf 'warn: %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'fail: %s\n' "$1"
}

require_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    ok "$name -> $(command -v "$name")"
  else
    fail "missing command: $name"
  fi
}

recommend_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    ok "$name -> $(command -v "$name")"
  else
    warn "missing recommended command: $name"
  fi
}

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    ok "$path exists"
  else
    fail "$path is missing"
  fi
}

check_contains() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if [[ -f "$path" ]] && grep -Fq "$pattern" "$path"; then
    ok "$label"
  else
    fail "$label"
  fi
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

usage() {
  cat <<'USAGE'
Usage:
  ./verify-linux.sh
  ./verify-linux.sh --command <name> [--command <name> ...]
  ./verify-linux.sh --feature trash|rtk|rules|skills|clip-run|arch-sudoers [--feature ...]

With no arguments, runs a full baseline check. For Linux setup, agents can install one package and immediately verify only the command or feature they just changed.
USAGE
}

commands=()
features=()
if (($#)); then
  while (($#)); do
    case "$1" in
      --command)
        commands+=("${2:-}")
        shift 2
        ;;
      --feature)
        features+=("${2:-}")
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
fi

printf 'Coding Agents Linux verification\n'
printf 'kernel: %s\n' "$(uname -a)"
printf 'shell: %s\n' "${SHELL:-unknown}"

check_trash() {
  require_command trash
  require_command trash-put
  if command -v pacman >/dev/null 2>&1 && command -v trash >/dev/null 2>&1; then
    if pacman -Qo "$(command -v trash)" 2>/dev/null | grep -Fq 'trash-cli'; then
      ok 'trash is provided by system trash-cli package'
    else
      warn 'trash is not reported as pacman trash-cli; verify it is a FreeDesktop trash implementation'
    fi
  fi
}

check_rtk() {
  require_command rtk
  if command -v rtk >/dev/null 2>&1; then
    if rtk --version 2>/dev/null | grep -Eq '^rtk[[:space:]][0-9]' && rtk --help 2>/dev/null | grep -Fq 'token-optimized output'; then
      ok 'rtk-ai/rtk CLI detected'
    else
      fail 'rtk exists but does not look like rtk-ai/rtk'
    fi
  fi
}

check_rules() {
  check_file "$HOME/.codex/AGENTS.md"
  check_file "$HOME/.claude/CLAUDE.md"
  check_contains "$HOME/.codex/AGENTS.md" '# Linux Environment' 'Codex rules include Linux fragment'
  check_contains "$HOME/.claude/CLAUDE.md" '# Linux Environment' 'Claude rules include Linux fragment'
  if is_arch_like; then
    check_contains "$HOME/.codex/AGENTS.md" '# Arch Linux Environment' 'Codex rules include Arch Linux fragment'
    check_contains "$HOME/.claude/CLAUDE.md" '# Arch Linux Environment' 'Claude rules include Arch Linux fragment'
  fi
}

check_skills() {
  if [[ -d "$HOME/.agents/skills" ]]; then
    ok "$HOME/.agents/skills exists"
  else
    warn "$HOME/.agents/skills is missing"
  fi
}

check_clip_run() {
  require_command clip-run
}

check_arch_sudoers() {
  if ! is_arch_like; then
    warn 'not an Arch-family system; skipping pacman/paru sudoers check'
    return
  fi

  local sudo_list
  if ! sudo_list="$(sudo -n -l 2>/dev/null)"; then
    warn 'sudo -n -l failed; package-manager sudoers may require an interactive password'
    return
  fi

  if grep -Eq 'NOPASSWD:[[:space:]]+/usr/bin/pacman([[:space:]]|$)' <<<"$sudo_list"; then
    ok 'sudoers allows /usr/bin/pacman without an interactive password'
  else
    warn 'sudoers does not show NOPASSWD for /usr/bin/pacman'
  fi

  if command -v paru >/dev/null 2>&1; then
    if grep -Eq 'NOPASSWD:[[:space:]]+/usr/bin/paru([[:space:]]|$)' <<<"$sudo_list"; then
      ok 'sudoers allows /usr/bin/paru without an interactive password'
    else
      warn 'sudoers does not show NOPASSWD for /usr/bin/paru'
    fi
  fi
}

if ((${#commands[@]})); then
  for cmd in "${commands[@]}"; do
    require_command "$cmd"
  done
fi

if ((${#features[@]})); then
  for feature in "${features[@]}"; do
    case "$feature" in
      trash) check_trash ;;
      rtk) check_rtk ;;
      rules) check_rules ;;
      skills) check_skills ;;
      clip-run) check_clip_run ;;
      arch-sudoers) check_arch_sudoers ;;
      *)
        fail "unknown feature: $feature"
        ;;
    esac
  done
fi

if ((! ${#commands[@]} && ! ${#features[@]})); then
  for cmd in git rg bun bunx uv uvx python3; do
    require_command "$cmd"
  done
  check_trash
  check_rtk
  check_clip_run
  for cmd in fd bat eza zoxide fzf jq dust duf procs btm delta kimi-webbridge; do
    recommend_command "$cmd"
  done
  check_rules
  check_skills
  if is_arch_like; then
    check_arch_sudoers
  fi
fi

printf '\nsummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
