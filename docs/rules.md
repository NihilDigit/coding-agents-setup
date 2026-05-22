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

`AGENTS.shared.md` should stay platform-neutral. Put shell aliases, package manager installation details, and platform paths into platform fragments. Put agent-specific directory conventions and runtime notes into adapter fragments.

Linux setup uses:

```text
rules/AGENTS.shared.md
rules/AGENTS.linux.md
rules/AGENTS.linux-arch.md when `/etc/os-release` is Arch-like
rules/AGENTS.codex.md or rules/CLAUDE.md
rules/AGENTS.linux-initial-setup.md
```

The Linux fragment contains stable platform defaults such as system `trash-cli`, `clip-run`, and RTK guidance. Arch-specific package-manager guidance lives in `AGENTS.linux-arch.md` and is only composed on Arch-like systems. The Linux initial-setup fragment is intentionally temporary. It tells the agent to inspect the machine, ask the user which setup steps they want, and personalize the local environment. Delete it from the generated agent file after the first Linux setup pass.
