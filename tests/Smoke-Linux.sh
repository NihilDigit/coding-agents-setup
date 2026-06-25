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
rtk --version 2>/dev/null | grep -Eq '^rtk[[:space:]][0-9]'
rtk --help 2>/dev/null | grep -Fq 'token-optimized output'
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

# Test tag-conditional rule filtering (same awk logic as join_rules)
filter_test_file="$(mktemp)"
cat > "$filter_test_file" <<'EOF'
# Common header

<!-- :windows-only -->
## Windows specific
Windows content
<!-- :end -->

<!-- :linux-only -->
## Linux specific
Linux content
<!-- :end -->

<!-- :codex-only -->
Codex browser content
<!-- :end -->

<!-- :claude-only :pi-only -->
Agent browser content
<!-- :end -->

## Shared footer
EOF

filter_rules() {
  local active_tags="$1"
  awk -v active_csv="$active_tags" '
    BEGIN {
      split(active_csv, tags, ",")
      for (i in tags) {
        if (tags[i] != "") active[tags[i]] = 1
      }
      in_block = 0
      keep_block = 1
    }
    function is_condition_marker(line) {
      return line ~ /^[[:space:]]*<!--[[:space:]]*(:[[:alnum:]-]+-only[[:space:]]*)+-->[[:space:]]*$/
    }
    function is_end_marker(line) {
      return line ~ /^[[:space:]]*<!--[[:space:]]*:end[[:space:]]*-->[[:space:]]*$/
    }
    {
      if (is_condition_marker($0)) {
        condition = $0
        sub(/^[[:space:]]*<!--[[:space:]]*/, "", condition)
        sub(/[[:space:]]*-->[[:space:]]*$/, "", condition)
        count = split(condition, parts, /[[:space:]]+/)
        keep_block = 0
        for (i = 1; i <= count; i++) {
          tag = parts[i]
          sub(/^:/, "", tag)
          sub(/-only$/, "", tag)
          if (tag in active) keep_block = 1
        }
        in_block = 1
        next
      }
      if (is_end_marker($0)) {
        in_block = 0
        keep_block = 1
        next
      }
      if (!in_block || keep_block) print
    }
  ' "$filter_test_file"
}

filtered="$(filter_rules 'linux,codex')"
filtered_pi="$(filter_rules 'linux,pi')"
rm -f "$filter_test_file"

echo "$filtered" | grep -Fq 'Linux specific' || { echo 'Linux content was stripped on Linux' >&2; exit 1; }
echo "$filtered" | grep -Fq 'Windows specific' && { echo 'Windows content was not stripped on Linux' >&2; exit 1; }
echo "$filtered" | grep -Fq 'Codex browser content' || { echo 'Codex content was stripped for Codex' >&2; exit 1; }
echo "$filtered" | grep -Fq 'Agent browser content' && { echo 'Non-Codex agent browser content leaked into Codex output' >&2; exit 1; }
echo "$filtered_pi" | grep -Fq 'Agent browser content' || { echo 'Multi-tag Pi content was stripped for Pi' >&2; exit 1; }
echo "$filtered_pi" | grep -Fq 'Codex browser content' && { echo 'Codex content leaked into Pi output' >&2; exit 1; }
echo "$filtered" | grep -Fq '<!-- :' && { echo 'Conditional markers leaked through filtering' >&2; exit 1; }
echo "$filtered_pi" | grep -Fq '<!-- :' && { echo 'Conditional markers leaked through Pi filtering' >&2; exit 1; }
ok 'tag-conditional rule filtering strips inactive blocks on Linux'

printf 'Linux behavior smoke passed\n'
