# Coding Agents Setup

Shared setup files for local coding agents.

The repo keeps the rules as small Markdown fragments, then writes the agent-specific file during setup:

```text
rules/AGENTS.shared.md
rules/AGENTS.windows.md
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

Linux is intentionally lighter. It only writes agent Markdown files and includes a temporary first-run task for the agent to inspect the machine and ask what to configure:

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

The Windows installer configures tools and shell ergonomics. The Linux installer only writes agent Markdown files and leaves environment setup to the agent after it inspects the machine.

Linux has a deliberately small helper for cloned checkouts:

```bash
./setup-linux.sh --agent both
```

It only writes agent rule files and includes a temporary bootstrap note in the generated Markdown. It does not install packages or modify shell profiles.
The temporary Linux section is an instruction for the agent to inspect the machine, ask what to configure, and then personalize the setup locally.
