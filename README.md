# Coding Agents Setup

Installs or writes user-level configuration for Codex, Claude, and Pi coding agents. Handles Windows and Linux separately.

## TL;DR

Rule files and setup scripts that encode local coding-agent conventions: available tools, package-manager preferences, file deletion behavior, operations that require user confirmation, and platform differences.

Uses `uv` for Python, `bun` for JS/TS, and CLI tools such as `rg`, `fd`, and `eza`.

Managed files are backed up before replacement. CI runs smoke checks on Ubuntu and Windows.

## Rule Fragments

Rules are composed from Markdown fragments per agent.

**Codex:** `AGENTS.shared.md` + `AGENTS.windows.md` + `AGENTS.codex.md` → `~/.codex/AGENTS.md`

**Claude Code:** `AGENTS.shared.md` + `AGENTS.windows.md` + `CLAUDE.md` → `~/.claude/CLAUDE.md`

**Pi:** `AGENTS.shared.md` + `AGENTS.windows.md` + `AGENTS.pi.md` → `~/.pi/agent/AGENTS.md`

`AGENTS.shared.md` defines shared contracts: toolchain, permissions, file safety, and the Issue-Driven Work Contract (alignment before implementation). Platform details go into platform fragments. Agent-specific conventions go into adapter fragments.

**Linux variant:** uses `AGENTS.linux.md` instead of `AGENTS.windows.md`, adds `AGENTS.linux-arch.md` on Arch-like systems, and includes `AGENTS.linux-initial-setup.md` (delete after first pass).

## Agent Targets

| Agent | Windows `-Agent` | Linux `--agent` |
|-------|------------------|-----------------|
| Codex | `Codex` | `codex` |
| Claude | `Claude` | `claude` |
| Pi | `Pi` | `pi` |
| All | `All` | `all` |
| Tooling only | `None` | `none` |

## Install

Review the scripts before running remote bootstrap commands. They download code and execute it locally.

By default, bootstrap uses the commit from the latest successful `ci-*` smoke run.

Windows:

```powershell
irm https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.ps1 | iex
```

Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.sh | bash
```

From a checkout:

```powershell
.\setup-windows.ps1 -Agent Pi
```

```bash
./setup-linux.sh --agent pi
```

Test a branch:

```bash
curl -fsSL https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.sh | REF=main REF_KIND=branch bash
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.ps1))) -Ref main -RefKind branch
```

## Windows

Full interactive setup. Installs toolchain, writes agent rule files, writes PowerShell profile with safe `rm → trash`, sets up Agent Skills directories, installs `rtk`, and optionally `agent-browser`.

Bootstraps PowerShell 7 if missing, sets execution policy to `RemoteSigned`, and prefers pwsh as the default Windows Terminal profile.

PowerShell profile writing is interactive. Unix-style aliases (`ls → eza`, `grep → rg`, etc.) and safe `rm` are opt-in (default yes).

Flags:

| Flag | Effect |
|------|--------|
| `-Yes` | Accept all prompts, including those defaulting to no |
| `-NonInteractive` | Conservative defaults, no prompts |
| `-SkipTools` | Only write rules and profile |
| `-SkipProfile` | Only write rules and install tools |

## Linux

Writes rule files and `~/.local/bin/clip-run` only. Does not install system packages or modify shell profiles. Linux environments vary too much for a single automated flow; inspect the machine and ask the user what to configure.

On Arch-like systems, generated rules add `paru`/`pacman` guidance, `*-bin` AUR preference, system `trash-cli`, and narrow sudoers configuration.

`clip-run` writes a script to `/tmp` and copies the run command to the clipboard for manual execution.

After the first setup pass, delete the `Linux Initial Setup Task` section from the generated agent file.

## Safety

Silent install and update are acceptable when scoped to the requested setup. Silent deletion is not.

Files are backed up before replacement:

- **Linux:** `*.bak-<timestamp>` adjacent to agent rules and `clip-run`.
- **Windows:** `~/.coding-agents-backup-<timestamp>` for rules, profiles, selection state, and `rtk.exe`. Existing `~/.claude/skills` is moved to `.old-<timestamp>`.

## Verify

Linux:

```bash
./verify-linux.sh --feature trash
./verify-linux.sh --command paru --feature arch-sudoers
./verify-linux.sh
bash tests/Smoke-Linux.sh
```

Windows:

```powershell
.\verify-windows.ps1
.\tests\Smoke-Windows.ps1
```

Repository:

```powershell
pwsh -NoLogo -NoProfile -File tests/Test-Setup.ps1
```

## CI

Smoke tests (Ubuntu + Windows) run when a `ci-*` tag is pushed:

```bash
tag="ci-$(date -u +%Y%m%d%H%M%S)"
git tag --no-sign "$tag"
git push origin "$tag"
```

Remote install defaults to the commit from the latest successful `ci-*` smoke run.
