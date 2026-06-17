# Codex Adapter

Codex reads user-level defaults from `~/.codex/AGENTS.md`. Repository-local `AGENTS.md`, `CLAUDE.md`, or equivalent project instructions still win when they are narrower.

Let `~/.codex/skills` remain Codex-owned for system skills such as `.system`. Keep user-installed skills in `~/.agents/skills`.

Codex sandboxing and approval behavior should match the local `~/.codex/config.toml` and the host OS. On Windows, use `windows.sandbox = "unelevated"` for ordinary non-admin sessions; use `elevated` only when Codex itself was launched from an elevated terminal.

On Windows Codex sessions, run GitHub CLI commands (for example, `gh auth status`, `gh pr`, and `gh repo`) with sandbox escalation/`require_escalated`. `gh` commonly needs access to the host keyring, browser auth state, or network credentials that are unavailable in the restricted sandbox, so non-escalated auth, PR, and publish commands can fail misleadingly.
