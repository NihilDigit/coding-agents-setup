# Coding Agents Setup

This file defines default behavior for coding agents working with this user. It applies across projects unless a repository-local `AGENTS.md`, `CLAUDE.md`, or equivalent project instruction gives narrower rules. Repository-local instructions always win.

## Workflow

For broad implementation work, use this simple shape:

1. Align with the user on the fuzzy idea until the target, constraints, and non-goals are concrete enough to act on.
2. Help the user build a practical model of how the agent discovers the problem, analyzes it, chooses a fix, and verifies the result.
3. Start implementation only after that shared model is clear enough for the user to understand the direction.

Keep this lightweight. The point is not ceremony; the point is to avoid silently turning vague intent into hidden architecture decisions.

For reviews, lead with findings ordered by severity, including file and line references. If no issues are found, say so and mention remaining test gaps or residual risk.

## Local Toolchain

Prefer the user's local tools and package managers:

- JS/TS: use `bun` instead of `npm`, `yarn`, or direct `node` commands when the project permits it.
- Python: use `uv` instead of ad-hoc `pip`, `venv`, or `poetry` workflows unless the project already requires another tool.
- Python CLI tools: use `uv tool install` for reusable tools.
- One-off Python commands: use `uvx`.
- One-off JS commands: use `bunx`.
- ML or GPU-heavy environments with mixed dependencies: prefer `pixi` when the project uses it.
- Arch/Linux system packages on this user's machines: use `paru -S` or `sudo pacman -S` when installation is explicitly needed.
- Token-heavy command output: use `rtk` manually for compact output when exact raw logs are not required. `rtk` is this machine's local output-compaction helper for grep/read/find/git/test command summaries.

If a project pins another toolchain, follow the project. Examples: use `npm` when `package-lock.json` and scripts require it; use Poetry/PDM when the repo is built around it; use `pnpm` when the lockfile and scripts require it.

## Agent Skills

Manage Agent Skills with the CLI as `bunx skills ...`. Keep user-installed skills in `~/.agents/skills`; by default keep `writing-style`, `impeccable`, and `kimi-webbridge` there.

## Permission Model

Treat the local agent session as a fast development lane, not as permission to ignore boundaries.

Read-only inspection commands and common local `bun`/`uv` development commands may be auto-allowed. Use them freely for context gathering, tests, typechecks, and local project workflows.

Cross-directory writes, network access, dependency installation, broad command runners, destructive file operations, GUI launches, and privileged system commands still require explicit approval or a clearly justified escalation request.

Prefer narrow commands over broad interpreters. For example, use `bun test`, `bun run <script>`, `uv run <tool>`, or a project test command instead of a generic shell, Python, or curl pipeline when a narrower entry point exists.

When a package or small tool is clearly needed and low risk, install it using the preferred order above. Keep installs scoped and explain what was installed.

## File Safety

Use the installed `trash` command for deleting user or project files when available; restore deleted files through the platform trash or recycle bin. The npm `trash-cli` package provides `trash` but not `trash-put`, `trash-list`, or `trash-restore`.

Before editing an untracked file, create a timestamped `.bak` copy first. Check tracking with:

```bash
git ls-files --error-unmatch <file>
```

Exit code `0` means the file is tracked, so skip the backup. Non-zero means it is untracked; back it up before editing.

Do not use `git checkout` mid-session unless explicitly requested. Commits usually happen at session end, and checkout can drop uncommitted changes. Avoid hard resets, force checkouts, force pushes, and broad cleanup commands unless the user explicitly asks for them.

## Command Output Discipline

Prefer `rg`/`rg --files` for search. Use compact output when raw logs are not needed:

```bash
rtk grep ...
rtk read ...
rtk find ...
rtk git status
rtk git diff
rtk pytest
rtk cargo test
rtk tsc
rtk next build
```

Do not use `rtk` when exact raw output is the artifact being inspected, copied, or reported.

## Browser Use

For current web facts, use browser/search tooling and cite sources. For local browser automation, use the `kimi-webbridge` skill and prefer Kimi WebBridge when installed: it drives the user's real Chrome/Edge session for navigation, clicks, forms, screenshots, and page extraction. Keep browser actions read-only by default, and ask before submitting forms, changing settings, sending messages, deleting data, purchasing, or touching account-sensitive state.

Official references:

- https://www.kimi.com/features/webbridge
- https://www.kimi.com/help/kimi-webbridge/kimi-webbridge-introduction
- https://www.kimi.com/help/kimi-webbridge/kimi-webbridge-how-it-works
