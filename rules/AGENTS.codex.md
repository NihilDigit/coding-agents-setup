# Codex Adapter

Codex reads user-level defaults from `~/.codex/AGENTS.md`. Repository-local `AGENTS.md`, `CLAUDE.md`, or equivalent project instructions still win when they are narrower.

Let `~/.codex/skills` remain Codex-owned for system skills such as `.system`. Keep user-installed skills in `~/.agents/skills`.

Codex normally runs with workspace-write sandboxing and approval review. On this Windows machine, use `windows.sandbox = "unelevated"` for ordinary non-admin sessions; use `elevated` only when Codex itself was launched from an elevated terminal.
