# Codex Adapter

Codex reads user-level defaults from `~/.codex/AGENTS.md`. Repository-local `AGENTS.md`, `CLAUDE.md`, or equivalent project instructions still win when they are narrower.

Let `~/.codex/skills` remain Codex-owned for system skills such as `.system`. Keep user-installed skills in `~/.agents/skills`.

Codex sandboxing and approval behavior should follow the permissions block supplied to the current session, not assumptions from `~/.codex/config.toml` alone. Desktop and managed Codex sessions can run with a narrower effective sandbox than the local config file suggests.

On Linux, treat `workspace-write` plus explicit escalation as the normal local permission model. Read-only repository inspection, local test commands, and package-manager commands already allowed by the session may run in the sandbox. Use sandbox escalation/`require_escalated` for operations that need host identity, host devices, network credentials, or writes outside the current workspace.

Run these command families with escalation by default:

- Serial and hardware access, including `/dev/ttyACM*`, `/dev/ttyUSB*`, `mpremote`, `esptool`, `adb`, `fastboot`, and similar device tools. The sandbox can drop supplemental groups such as `uucp`, so host serial permissions may only be visible outside the sandbox.
- GitHub CLI commands, including `gh auth status`, `gh repo`, `gh pr`, `gh issue`, and release/publish flows. `gh` commonly needs the host keyring, browser auth state, and network credentials.
- Network-dependent package and tool acquisition, including `uvx`, `bunx`, `npm`, `pip`, and language-specific package managers when they need registry access.
- Browser, GUI, desktop automation, keyring, credential-store, and account-auth flows.
- Cross-directory writes, privileged commands, system package manager commands, and commands that need host network or device state rather than only files in the current workspace.

When escalating, keep the command narrow and explain why the host context is required. Prefer prefix rules that match the exact command family, such as `["gh", "pr"]`, `["gh", "auth"]`, `["uvx", "mpremote"]`, or `["sudo", "pacman"]`; do not request broad interpreter prefixes for arbitrary scripts.

On Windows, use `windows.sandbox = "unelevated"` for ordinary non-admin sessions; use `elevated` only when Codex itself was launched from an elevated terminal. GitHub CLI commands on Windows should also use escalation for the same keyring, browser-auth, and network reasons.
