#!/usr/bin/env bash
set -euo pipefail

ok() {
  printf 'ok: %s\n' "$1"
}

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "missing command: $name" >&2
    exit 1
  fi
  ok "$name -> $(command -v "$name")"
}

for cmd in git rg bun bunx uv uvx python3 trash-put rtk clip-run; do
  require_command "$cmd"
done

git --version >/dev/null
rg --version >/dev/null
bun --version >/dev/null
bunx --version >/dev/null
uv --version >/dev/null
uvx --version >/dev/null
python3 --version >/dev/null
rtk gain >/dev/null
ok 'core commands execute'

trash_target="$(mktemp)"
printf 'trash smoke\n' > "$trash_target"
trash-put "$trash_target"
if [[ -e "$trash_target" ]]; then
  echo "trash-put did not remove $trash_target from its original path" >&2
  exit 1
fi
ok 'trash-put moves a temp file out of its original path'

clip_name="coding-agents-smoke-$RANDOM-$$"
printf 'printf "clip-run smoke\\n"\n' | clip-run "$clip_name" >/tmp/"$clip_name.out"
clip_script="/tmp/$clip_name.sh"
if [[ ! -x "$clip_script" ]]; then
  echo "clip-run did not create executable script: $clip_script" >&2
  exit 1
fi
bash "$clip_script" | grep -Fx 'clip-run smoke' >/dev/null
ok 'clip-run writes an executable handoff script'

printf 'Linux behavior smoke passed\n'
