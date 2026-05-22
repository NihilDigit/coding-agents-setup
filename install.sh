#!/usr/bin/env bash
set -euo pipefail

repo="${REPO:-NihilDigit/coding-agents-setup}"
ref="${REF:-main}"
agent="${AGENT:-prompt}"

printf '%s\n' 'This bootstrap downloads setup-linux.sh and rule fragments from GitHub.'
printf '%s\n' 'It only writes agent Markdown files; it does not install packages or edit shell profiles.'

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/coding-agents-setup.XXXXXX")"
archive="$tmp_dir/repo.tar.gz"
extract="$tmp_dir/repo"
mkdir -p "$extract"

curl -fsSL "https://github.com/$repo/archive/refs/heads/$ref.tar.gz" -o "$archive"
tar -xzf "$archive" -C "$extract" --strip-components=1

exec bash "$extract/setup-linux.sh" --agent "$agent"
