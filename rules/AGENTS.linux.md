# Linux Environment

This Linux setup keeps package and shell changes explicit. The setup script writes agent rules and installs user-local helpers only; install system tools through the local package manager after inspecting the machine.

## Linux Tooling Defaults

Prefer system packages for common CLI tools. Use the distribution package manager unless a project pins another toolchain.

Package installation and updates may run non-interactively for setup work. Package removal, cache cleanup, orphan pruning, and file deletion must not be silent; ask first and prefer `trash-put` for file deletion.

## Linux Trash

Use the distro `trash-cli` package on Linux. It provides `trash`, `trash-put`, `trash-list`, `trash-restore`, and related FreeDesktop trash helpers. Do not use the npm `trash-cli` package for Linux setup.

Do not alias `rm` globally unless the user explicitly accepts that shell behavior. When deletion is necessary, prefer `trash-put <path>` for user or project files.

## Linux Handoff Helper

The Linux setup installs `clip-run` to `~/.local/bin/clip-run`. Use it for commands the user must run manually, especially privileged setup that still needs an interactive sudo password:

```bash
clip-run <name>
```

It reads a script from stdin, writes it to `/tmp/<name>.sh`, makes it executable, and copies `bash /tmp/<name>.sh` to the clipboard when a clipboard tool is available.

## RTK

Install `rtk-ai/rtk` when token-heavy command output should be compacted:

```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | bash
```

Verify the expected RTK with `rtk gain`; this distinguishes it from unrelated packages that also use the `rtk` name.
