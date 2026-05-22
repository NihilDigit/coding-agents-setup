# Coding Agents Setup

Shared setup files for local coding agents.

The repo keeps the rules as small Markdown fragments, then writes the agent-specific file during setup:

```text
rules/AGENTS.shared.md
rules/AGENTS.windows.md
rules/AGENTS.linux.md
rules/AGENTS.linux-arch.md
rules/AGENTS.codex.md
rules/CLAUDE.md
```

On Windows, `setup-windows.ps1` composes those fragments into:

```text
~/.codex/AGENTS.md   = shared + windows + codex
~/.claude/CLAUDE.md  = shared + windows + claude
```

The shared fragment contains behavior that should apply to any coding agent: workflow, toolchain preferences, skills, file safety, output discipline, and browser-use policy. Platform-specific shell behavior stays in a platform fragment. Agent-specific notes stay in adapter fragments.

## Install

Windows is the full interactive setup. It can install tools, write PowerShell profile helpers, configure skills layout, and write agent rules:

```powershell
irm https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.ps1 | iex
```

Linux is intentionally lighter. It writes agent Markdown files, installs small user-local helpers such as `clip-run`, and includes a temporary first-run task for the agent to inspect the machine and ask what to configure:

```bash
curl -fsSL https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.sh | bash
```

Set the target agent non-interactively:

```bash
curl -fsSL https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.sh | AGENT=claude bash
```

From a cloned checkout:

```powershell
.\setup-windows.ps1 -Agent Both
```

Non-interactive install:

```powershell
.\setup-windows.ps1 -Agent Both -Yes
```

Rules only, without installing tools or writing PowerShell profiles:

```powershell
.\setup-windows.ps1 -Agent Codex -SkipTools -SkipProfile
```

Remote Windows bootstrap, after reviewing `install.ps1` and the repository:

```powershell
irm https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.ps1 | iex
```

The Windows bootstrap downloads the repository archive and runs `setup-windows.ps1`. It is intentionally thin so the versioned setup script remains the source of truth.

## Agent Targets

`-Agent` accepts:

- `Codex`: write `~/.codex/AGENTS.md`
- `Claude`: write `~/.claude/CLAUDE.md`
- `Both`: write both
- `None`: install shared tooling only
- `Prompt`: ask interactively

## Repository Policy

Do not put machine-specific SDK inventories, device IDs, or project paths in shared rules. Keep those in a private local note or in the relevant project repository.

The Windows installer configures tools and shell ergonomics. The Linux installer writes agent Markdown files, installs user-local helpers, and leaves system package setup to the agent after it inspects the machine.

Linux has a deliberately small helper for cloned checkouts:

```bash
./setup-linux.sh --agent both
```

It writes agent rule files, installs `~/.local/bin/clip-run`, and includes a temporary bootstrap note in the generated Markdown. It does not install system packages or modify shell profiles.
The temporary Linux section is an instruction for the agent to inspect the machine, ask what to configure, and then personalize the setup locally.

## Backups

Setup backs up persistent files before replacing them:

- Linux: adjacent `*.bak-<timestamp>` backups for generated agent rules and `~/.local/bin/clip-run`.
- Windows: backups under `~/.coding-agents-backup-<timestamp>` for generated agent rules, PowerShell profiles, setup selection state, and `~/.local/bin/rtk.exe`.
- Windows skills layout: existing `~/.claude/skills` links or directories are moved to `.old-<timestamp>` before the new link is created.

## Verify

Linux verification is incremental by design:

```bash
./verify-linux.sh --feature trash
./verify-linux.sh --command paru --feature arch-sudoers
./verify-linux.sh
```

Windows verification reads the selection state written by `setup-windows.ps1` and checks the tools the user actually chose to install:

```powershell
.\verify-windows.ps1
```

Use `.\verify-windows.ps1 -Recommended` to also show warnings for recommended tools that were not selected.
