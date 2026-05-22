# Coding Agents Setup

Shared setup files for local coding agents. The scripts compose small rule fragments into the right user-level files for Codex and Claude, with platform-specific behavior kept separate.

## TL;DR

This is a personal coding-agent setup pipeline, shaped by the practices I have found useful while working with Codex, Claude, and local developer tools. It is opinionated, but meant to be inspectable and reusable.

It installs or writes only user-level configuration, backs up managed files before replacing them, and keeps Windows/Linux behavior split instead of forcing one shared setup path. If those tradeoffs match how you work, it may be useful as-is or as a starting point.

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
.\setup-windows.ps1 -Agent Both
```

```bash
./setup-linux.sh --agent both
```

Test a branch instead of the latest tested tag:

```bash
curl -fsSL https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.sh | REF=main REF_KIND=branch bash
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.ps1))) -Ref main -RefKind branch
```

## Windows

Windows is the full interactive setup. It can install developer tools, `rtk`, JS `trash-cli`, Agent Skills, Kimi WebBridge, Codex/Claude rules, and PowerShell profile blocks.

PowerShell profile writing is interactive. The default profile adds PATH entries and helper functions. A second prompt enables Unix-style aliases, including safe `rm -> trash` shadowing; the default is yes.

Kimi WebBridge is offered by default and can be declined. It downloads and executes Kimi's current installer, and browser extension/profile access may be required for full browser automation.

`-Yes` accepts every setup prompt, including prompts whose interactive default is no:

```powershell
.\setup-windows.ps1 -Agent Both -Yes
```

Rules only:

```powershell
.\setup-windows.ps1 -Agent Codex -SkipTools -SkipProfile
```

## Linux

Linux setup is intentionally lighter. It writes agent rule files, installs `~/.local/bin/clip-run`, and includes a temporary first-run task for the agent to inspect the machine and ask what to configure.

It does not install system packages or modify shell profiles.

On Arch-like systems, generated rules add Arch-specific guidance: use `paru -S` or `sudo pacman -S`, prefer `*-bin` AUR packages when available, use system `trash-cli`, and configure sudoers narrowly for `/usr/bin/pacman` and `/usr/bin/paru`.

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

GitHub Actions runs smoke tests on Ubuntu and Windows when a `ci-*` tag is pushed:

```bash
tag="ci-$(date -u +%Y%m%d%H%M%S)"
git tag --no-sign "$tag"
git push origin "$tag"
```

## Rule Fragments

Shared:

```text
rules/AGENTS.shared.md
rules/AGENTS.codex.md
rules/CLAUDE.md
```

Platform:

```text
rules/AGENTS.windows.md
rules/AGENTS.linux.md
rules/AGENTS.linux-arch.md
rules/AGENTS.linux-initial-setup.md
```

`AGENTS.linux-arch.md` is included only when `/etc/os-release` reports `ID=arch` or `ID_LIKE` contains `arch`.

## Agent Targets

Windows `-Agent`: `Codex`, `Claude`, `Both`, `None`, `Prompt`.

Linux `--agent`: `codex`, `claude`, `both`, `none`, `prompt`.
