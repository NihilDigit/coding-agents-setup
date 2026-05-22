#!/usr/bin/env bash
set -euo pipefail

repo="${REPO:-NihilDigit/coding-agents-setup}"
ref="${REF:-}"
ref_kind="${REF_KIND:-sha}"
agent="${AGENT:-prompt}"

printf '%s\n' 'This bootstrap downloads setup-linux.sh and rule fragments from GitHub.'
printf '%s\n' 'It writes agent Markdown files and user-local helpers; it does not install system packages or edit shell profiles.'

json_value() {
  if command -v python3 >/dev/null 2>&1; then
    python3 "$@"
  elif command -v python >/dev/null 2>&1; then
    python "$@"
  else
    echo "python3 or python is required to resolve the latest successful CI tag. Set REF and REF_KIND explicitly." >&2
    exit 1
  fi
}

latest_successful_ci_ref() {
  curl -fsSL "https://api.github.com/repos/$repo/actions/workflows/smoke.yml/runs?status=success&event=push&per_page=50" |
    json_value -c '
import json, sys
data = json.load(sys.stdin)
for run in data.get("workflow_runs", []):
    tag = run.get("head_branch") or ""
    sha = run.get("head_sha") or ""
    if tag.startswith("ci-") and sha:
        print(f"{tag} {sha}")
        break
'
}

if [[ -z "$ref" ]]; then
  ci_ref="$(latest_successful_ci_ref)"
  if [[ -z "$ci_ref" ]]; then
    echo "Could not determine latest successful ci-* tag for $repo. Set REF and REF_KIND explicitly." >&2
    exit 1
  fi
  ci_tag="${ci_ref%% *}"
  ref="${ci_ref#* }"
  ref_kind="sha"
fi

case "$ref_kind" in
  tag) ref_path="tags" ;;
  branch) ref_path="heads" ;;
  sha) ref_path="" ;;
  *)
    echo "REF_KIND must be 'sha', 'tag', or 'branch'." >&2
    exit 2
    ;;
esac

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/coding-agents-setup.XXXXXX")"
archive="$tmp_dir/repo.tar.gz"
extract="$tmp_dir/repo"
mkdir -p "$extract"

if [[ "$ref_kind" == "sha" ]]; then
  if [[ -n "${ci_tag:-}" ]]; then
    printf 'Using latest successful CI tag %s at %s from %s\n' "$ci_tag" "$ref" "$repo"
  else
    printf 'Using commit %s from %s\n' "$ref" "$repo"
  fi
  curl -fsSL "https://github.com/$repo/archive/$ref.tar.gz" -o "$archive"
else
  printf 'Using %s %s from %s\n' "$ref_kind" "$ref" "$repo"
  curl -fsSL "https://github.com/$repo/archive/refs/$ref_path/$ref.tar.gz" -o "$archive"
fi
tar -xzf "$archive" -C "$extract" --strip-components=1

exec bash "$extract/setup-linux.sh" --agent "$agent"
