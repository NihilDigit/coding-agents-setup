# Coding Agents Setup

This file defines default behavior for coding agents working with this user. It applies across projects unless a repository-local `AGENTS.md`, `CLAUDE.md`, or equivalent project instruction gives narrower rules. Repository-local instructions always win.

## Issue-Driven Work Contract

When working from an Issue, problem analysis, PR brief, or any well-scoped task definition, the first output is alignment on the problem and approach, not code.

Consequences:

* Read the Issue or task definition first. Understand the problem boundary before broad code exploration.
* Discuss the task with the user before making product changes: what problem is being solved, what scope is implied, what will not be touched, risks, validation path, and open questions.
* Produce the appropriate brief before acting:

  * For exploration work, produce or refine the problem analysis.
  * For implementation work, produce an implementation brief: what will change, how, what will not be touched, risks, and validation plan.
* Present the brief to the user. Do not make product code changes or open a PR before the user approves the approach.
* After approval, proceed against the agreed scope. If new information changes the approach, pause and re-align.
* Exploration commands and temporary probes are allowed before approval when they validate assumptions: grep, typechecks, tests, logs, throwaway scripts, or local experiments.
* The final output must match the agreed brief. Scope changes during work trigger a new alignment cycle.

For reviews, lead with findings ordered by severity, including file and line references. If no issues are found, say so and mention remaining test gaps or residual risk.

For repositories owned by this user, default to working directly on the main branch unless the user explicitly asks for a PR-style branch and pull request workflow. When a branch is needed, use short type-prefixed names such as `feat/<topic>`, `fix/<topic>`, `docs/<topic>`, or `chore/<topic>`; do not default to agent-name prefixes. When opening a pull request, default the title to Conventional Commits form, for example `fix(scope): title` or `feat(scope): title`.

## Local Toolchain

Prefer the user's local tools and package managers:

- JS/TS: use `bun` instead of `npm`, `yarn`, or direct `node` commands when the project permits it.
- Python: use `uv` instead of ad-hoc `pip`, `venv`, or `poetry` workflows unless the project already requires another tool.
- Python CLI tools: use `uv tool install` for reusable tools.
- One-off Python commands: use `uvx`.
- One-off JS commands: use `bunx`.
- ML or GPU-heavy environments with mixed dependencies: prefer `pixi` when the project uses it.
- Arch/Linux system packages on this user's machines: use `paru -S` or `sudo pacman -S` when installation is explicitly needed.
- Token-heavy command output: use `rtk` manually for compact output when exact raw logs are not required.

If a project pins another toolchain, follow the project. Examples: use `npm` when `package-lock.json` and scripts require it; use Poetry/PDM when the repo is built around it; use `pnpm` when the lockfile and scripts require it.

## Agent Skills

Manage Agent Skills with the CLI as `bunx skills ...`. Keep user-installed skills in `~/.agents/skills`; by default keep `writing-style`, `impeccable`, and `agent-browser` there.

## Permission Model

Treat the local agent session as a fast development lane, not as permission to ignore boundaries.

Read-only inspection commands and common local `bun`/`uv` development commands may be auto-allowed. Use them freely for context gathering, tests, typechecks, and local project workflows.

Cross-directory writes, network access, broad command runners, destructive file operations, GUI launches, and privileged system commands still require explicit approval or a clearly justified escalation request. Dependency installation and updates may be non-interactive when they are scoped to the requested setup; uninstall, delete, cleanup, prune, and remove operations must not be silent.

Prefer narrow commands over broad interpreters. For example, use `bun test`, `bun run <script>`, `uv run <tool>`, or a project test command instead of a generic shell, Python, or curl pipeline when a narrower entry point exists.

When a package or small tool is clearly needed and low risk, install it using the preferred order above. Keep installs scoped and explain what was installed.

## File Safety

Use the platform-specific trash command for deleting user or project files when available; restore deleted files through the platform trash or recycle bin. Silent install is acceptable; silent deletion is not. Do not silently delete, uninstall, clean, prune, or remove user/project files, packages, profiles, skills, or configuration.

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

For current web facts, use browser/search tooling and cite sources.

For local browser automation, prefer `agent-browser` with the user's real Chrome profile in headed mode. The default user-level agent-browser config should keep:

```json
{
  "headed": true,
  "profile": "Default"
}
```

Invoke it with `agent-browser ...`; use `bunx agent-browser ...` as a fallback if the global binary is unavailable. This should reuse the user's logged-in Chrome state and show the browser window.

Keep browser actions read-only by default. Ask before submitting forms, changing settings, sending messages, deleting data, purchasing, or touching account-sensitive state.
