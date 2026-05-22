# Coding Agents Setup

Shared setup files for local coding agents.

The repository keeps user-level agent rules as small Markdown fragments, then composes the right file for each target agent and platform.

## Rule Fragments

Common fragments:

```text
rules/AGENTS.shared.md
rules/AGENTS.codex.md
rules/CLAUDE.md
```

Platform fragments:

```text
rules/AGENTS.windows.md
rules/AGENTS.linux.md
rules/AGENTS.linux-arch.md
rules/AGENTS.linux-initial-setup.md
```

`AGENTS.shared.md` stays platform-neutral. Shell aliases, package manager guidance, and platform paths belong in platform fragments. Agent-specific directory conventions belong in adapter fragments.

On Linux, `AGENTS.linux-arch.md` is included only when `/etc/os-release` reports `ID=arch` or an `ID_LIKE` value containing `arch`.

## Install

Review the scripts before running remote bootstrap commands. These commands download code and execute it locally.

Remote bootstrap defaults to the commit from the latest successful GitHub Actions smoke run triggered by a `ci-*` tag. To test a branch explicitly, set `REF` and `REF_KIND=branch` on Linux or `-Ref` and `-RefKind branch` on Windows.

Windows interactive setup:

```powershell
irm https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.ps1 | iex
```

Linux lightweight setup:

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

Set the Linux target agent non-interactively:

```bash
curl -fsSL https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.sh | AGENT=claude bash
```

Test a branch instead of the latest tested tag:

```bash
curl -fsSL https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.sh | REF=main REF_KIND=branch bash
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.ps1))) -Ref main -RefKind branch
```

## Windows

Windows is the full interactive setup. It can:

- install developer tools with `winget` and `bun`
- install `rtk.exe` from the latest `rtk-ai/rtk` GitHub release
- install the JS `trash-cli` package with `bun` for safe `trash` behavior
- configure `~/.agents/skills`, `~/.claude/skills`, and `~/.codex/skills`
- write Codex and Claude rule files
- write PowerShell profile blocks

PowerShell profile writing is interactive. The base profile block adds PATH entries, zoxide, and helper functions. A second prompt asks whether to enable recommended Unix-style aliases such as `ls -> eza`, `grep -> rg`, and safe `rm -> trash`; the default is yes.

Kimi WebBridge installation is also offered by default and can be declined interactively. It downloads and executes Kimi's current installer, and browser extension/profile access may be required for full browser automation.

`-Yes` accepts every setup prompt, including prompts whose interactive default is no. Use it only when you want the full install path:

```powershell
.\setup-windows.ps1 -Agent Both -Yes
```

Rules only, without installing tools or writing PowerShell profiles:

```powershell
.\setup-windows.ps1 -Agent Codex -SkipTools -SkipProfile
```

## Linux

Linux setup is intentionally lighter. It writes agent rule files, installs `~/.local/bin/clip-run`, and includes a temporary first-run task in the generated Markdown for the agent to inspect the machine and ask what to configure.

It does not install system packages or modify shell profiles.

On Arch-like systems, the generated rules recommend:

- using `paru -S` or `sudo pacman -S` for package installs
- preferring `*-bin` AUR packages when available
- using system `trash-cli`, not the npm package
- configuring sudoers for `/usr/bin/pacman` and `/usr/bin/paru`, not `NOPASSWD: ALL`

After the first Linux setup pass, delete the temporary `Linux Initial Setup Task` section from the generated agent file.

## Safety

Silent install and update are acceptable when scoped to the requested setup. Silent deletion is not.

Setup scripts should not silently delete, uninstall, clean, prune, or remove user files, packages, profiles, skills, or configuration. Existing managed files are backed up or moved aside first.

Remote bootstrap commands are intentionally thin wrappers:

- `install.ps1` downloads the repository archive and runs `setup-windows.ps1`.
- `install.sh` downloads the repository archive and runs `setup-linux.sh`.

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

Repository syntax checks:

```powershell
pwsh -NoLogo -NoProfile -File tests/Test-Setup.ps1
```

On Arch-like systems, install `powershell-bin` for repository development and script validation. Prefer the binary package over the source-build `powershell` AUR package.

GitHub Actions runs smoke tests on Ubuntu and Windows when a `ci-*` tag is pushed. To publish a tested bootstrap target, push a local tag such as:

```bash
tag="ci-$(date -u +%Y%m%d%H%M%S)"
git tag "$tag"
git push origin "$tag"
```

Remote bootstrap uses the newest successful `ci-*` tag run by default.

## Agent Targets

Windows `-Agent` accepts:

- `Codex`: write `~/.codex/AGENTS.md`
- `Claude`: write `~/.claude/CLAUDE.md`
- `Both`: write both
- `None`: install shared tooling only
- `Prompt`: ask interactively

Linux `--agent` accepts:

- `codex`: write `~/.codex/AGENTS.md`
- `claude`: write `~/.claude/CLAUDE.md`
- `both`: write both
- `none`: write no agent files
- `prompt`: ask interactively

## Repository Policy

Do not put machine-specific SDK inventories, device IDs, package inventories, or project paths in shared rules. Keep those in private local notes or in the relevant project repository.
