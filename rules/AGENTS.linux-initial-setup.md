# Linux Initial Setup Task

This section is temporary. It is a first-run task list for the agent, not a permanent rule. Delete it from this file after the Linux machine has been inspected and any useful local notes have been written.

On Linux, do not assume this repository knows the right package manager, shell, desktop environment, SDK paths, or trash implementation. Ask the user which setup steps they want, then configure the machine according to local facts.

Start by inspecting the machine without changing it:

```bash
uname -a
printf '%s\n' "$SHELL"
printf '%s\n' "$PATH"
command -v git rg fd fdfind bun bunx uv uvx python3 node npm pnpm trash trash-put gio kioclient5 kimi-webbridge webbridge
```

Then ask before doing any of these:

- Install or update base tools: `git`, `rg`, `fd`/`fdfind`, `bat`, `eza`, `zoxide`, `fzf`, `jq`, `dust`, `duf`, `procs`, `bottom`, `delta`.
- Install language tooling: `bun`/`bunx`, `uv`/`uvx`, project-specific Node/Python tooling, or any pinned project toolchain.
- Configure Agent Skills: keep user-installed skills in `~/.agents/skills`; add shell or symlink integration only after confirming what the target agent expects on that machine.
- Configure trash behavior: prefer a platform trash CLI such as `trash`, `trash-put`, `gio trash`, or the desktop environment's trash tool; do not alias `rm` until the user explicitly accepts the behavior.
- Configure Kimi WebBridge: explain that installing it may download and execute vendor code and may need a browser extension or browser profile access.
- Write shell startup changes: inspect the active shell first and ask before editing `.bashrc`, `.zshrc`, fish config, or profile files.
- Add local machine notes: keep SDK paths, attached device IDs, package inventories, and desktop-specific behavior in a private local note or machine-local rule file, not in shared repository rules.

Treat this as the Linux equivalent of what `setup-windows.ps1` automates on Windows, but do it interactively and locally because Linux environments vary too much for a single safe default.
