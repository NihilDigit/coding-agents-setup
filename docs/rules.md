# Rule Fragments

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

`AGENTS.shared.md` should stay platform-neutral by default. Put shell aliases, package manager installation details, and platform paths into platform fragments. Put agent-specific directory conventions and runtime notes into adapter fragments.

Fragments can contain conditional blocks when one shared section needs platform- or agent-specific wording:

```markdown
<!-- :codex-only -->
Only included for Codex.
<!-- :end -->

<!-- :claude-only :pi-only -->
Included for Claude Code and Pi.
<!-- :end -->
```

Supported tags are passed by the setup scripts during composition. Current tags include `windows`, `linux`, `arch`, `codex`, `claude`, and `pi`. A block is kept when any marker tag is active; otherwise the whole block is removed. Marker lines are never emitted into generated rule files.

Linux setup uses:

```text
rules/AGENTS.shared.md
rules/AGENTS.linux.md
rules/AGENTS.linux-arch.md when `/etc/os-release` is Arch-like
rules/AGENTS.codex.md or rules/CLAUDE.md
rules/AGENTS.linux-initial-setup.md
```

Pi:

```text
rules/AGENTS.shared.md
rules/AGENTS.windows.md
rules/AGENTS.pi.md
```

The Pi fragment contains agent-specific rules, including the Core Contract that defines the scout/recon workflow between the user and the agent.

Linux setup uses:

```text
rules/AGENTS.shared.md
rules/AGENTS.linux.md
rules/AGENTS.linux-arch.md when `/etc/os-release` is Arch-like
rules/AGENTS.codex.md or rules/CLAUDE.md or rules/AGENTS.pi.md
rules/AGENTS.linux-initial-setup.md
```

The Linux fragment contains stable platform defaults such as system `trash-cli`, `clip-run`, and RTK guidance. Arch-specific package-manager guidance lives in `AGENTS.linux-arch.md` and is only composed on Arch-like systems. The Linux initial-setup fragment is intentionally temporary. It tells the agent to inspect the machine, ask the user which setup steps they want, and personalize the local environment. Delete it from the generated agent file after the first Linux setup pass.
