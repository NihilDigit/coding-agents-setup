# Coding Agents Setup

A modern local toolchain setup for coding agents. It installs or writes user-level configuration for Codex, Claude, and Pi, with Windows and Linux behavior kept separate.

## TL;DR

This repo turns local coding-agent conventions into installable rule files and setup scripts: available tools, package-manager preferences, file deletion behavior, operations that require user confirmation, and platform differences.

Uses `uv` for Python, `bun` for JS/TS, and CLI replacements such as `rg`, `fd`, and `eza`.

Managed config files are backed up before replacement. CI runs installation and behavior smoke checks on Ubuntu and Windows.

## Rule Fragments

Rules are composed from Markdown fragments instead of maintained as separate full files.

Codex:

```text
rules/AGENTS.shared.md
rules/AGENTS.windows.md
rules/AGENTS.codex.md
```

Claude Code:

```text
rules/AGENTS.shared.md
rules/AGENTS.windows.md
rules/CLAUDE.md
```

Pi:

```text
rules/AGENTS.shared.md
rules/AGENTS.windows.md
rules/AGENTS.pi.md
```

`AGENTS.shared.md` stays platform-neutral. Platform details (shell aliases, package managers, paths) go into platform fragments. Agent-specific conventions go into adapter fragments.

Linux setup uses:

```text
rules/AGENTS.shared.md
rules/AGENTS.linux.md
rules/AGENTS.linux-arch.md when `/etc/os-release` is Arch-like
rules/AGENTS.codex.md or rules/CLAUDE.md or rules/AGENTS.pi.md
rules/AGENTS.linux-initial-setup.md
```

`AGENTS.linux-arch.md` is included only when `/etc/os-release` reports `ID=arch` or `ID_LIKE` contains `arch`. The initial-setup fragment is temporary—it tells the agent to inspect the machine and ask the user what to configure. Delete it after the first Linux setup pass.

## Agent Targets

| Agent | Windows `-Agent` | Linux `--agent` |
|-------|------------------|-----------------|
| Codex | `Codex` | `codex` |
| Claude Code | `Claude` | `claude` |
| Pi | `Pi` | `pi` |
| Codex + Claude | `Both` | `both` |
| Codex + Claude + Pi | `All` | `all` |
| None (tooling only) | `None` | `none` |

## Install

Review the scripts before running remote bootstrap commands. They download code and execute it locally.

By default, bootstrap downloads the commit from the latest successful GitHub Actions smoke run triggered by a `ci-*` tag.

Windows:

```powershell
irm https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.ps1 | iex
```

Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.sh | bash
```

From a cloned checkout:

```powershell
.\setup-windows.ps1 -Agent All
```

```bash
./setup-linux.sh --agent all
```

Single agent:

```powershell
.\setup-windows.ps1 -Agent Pi
```

```bash
./setup-linux.sh --agent pi
```

Test a branch instead of the latest tested tag:

```bash
curl -fsSL https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.sh | REF=main REF_KIND=branch bash
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.ps1))) -Ref main -RefKind branch
```

## Windows

Windows is the full interactive setup. It can install the toolchain, write Codex/Claude/Pi rule files, write a PowerShell profile, make `rm` send files to the Recycle Bin, set up Agent Skills directories, install `rtk`, and optionally install `agent-browser`.

The Windows bootstrap installs PowerShell 7 (`pwsh`) by default, runs setup through it, sets the current user's execution policy to `RemoteSigned`, and tries to make PowerShell 7 the default Windows Terminal profile. If a cloned checkout is blocked before the script can start, launch it once with:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1 -Agent All
```

PowerShell profile writing is interactive. The default profile adds PATH entries and helper functions. A second prompt enables Unix-style aliases, including safe `rm -> trash` shadowing; the default is yes.

`agent-browser` is offered by default and can be declined. It is installed with `bun`, runs `agent-browser install`, and writes `~/.agent-browser/config.json` so local browser automation runs headed with the user's `Default` Chrome profile.

`-Yes` accepts every setup prompt, including prompts whose interactive default is no:

```powershell
.\setup-windows.ps1 -Agent Codex -Yes
```

Rules only:

```powershell
.\setup-windows.ps1 -Agent Codex -SkipTools -SkipProfile
```

## Linux

Linux distributions and desktop environments vary too much for one fixed install flow. The Linux setup writes rule files first, installs `~/.local/bin/clip-run`, and includes a temporary first-run task for the agent to inspect the machine and ask what to configure.

It does not install system packages or modify shell profiles.

On Arch-like systems, generated rules add Arch-specific guidance: use `paru -S` or `sudo pacman -S`, prefer `*-bin` AUR packages when available, use system `trash-cli`, and configure sudoers narrowly for `/usr/bin/pacman` and `/usr/bin/paru`.

`clip-run` is used when an agent needs user confirmation or `sudo`: it writes a script to `/tmp` and copies the command for the user to run manually.

After the first Linux setup pass, delete the temporary `Linux Initial Setup Task` section from the generated agent file.

## Safety

Silent install and update are acceptable when scoped to the requested setup. Silent deletion is not.

Persistent files are backed up before replacement:

- Linux: adjacent `*.bak-<timestamp>` backups for generated agent rules and `~/.local/bin/clip-run`.
- Windows: backups under `~/.coding-agents-backup-<timestamp>` for generated rules, PowerShell profiles, setup selection state, and `~/.local/bin/rtk.exe`.
- Windows skills layout: existing `~/.claude/skills` links or directories are moved to `.old-<timestamp>`.

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

Repository checks:

```powershell
pwsh -NoLogo -NoProfile -File tests/Test-Setup.ps1
```

## CI

GitHub Actions runs smoke tests on Ubuntu and Windows when a `ci-*` tag is pushed. To trigger a release:

```bash
tag="ci-$(date -u +%Y%m%d%H%M%S)"
git tag --no-sign "$tag"
git push origin "$tag"
```

By default, remote install (```curl ... | bash``` / ```irm ... | iex```) uses the commit from the latest successful `ci-*` smoke run.
