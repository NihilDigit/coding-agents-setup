# Arch Linux Environment

This section applies to Arch-based Linux distributions, detected from `/etc/os-release` using `ID=arch` or an `ID_LIKE` value containing `arch`.

Install the recommended baseline with:

```bash
paru -S --needed git ripgrep fd bat eza zoxide fzf jq dust duf procs bottom git-delta trash-cli powershell-bin
```

Use `fd` on Arch-family systems; `fdfind` is the Debian/Ubuntu binary name.

Prefer `*-bin` AUR packages when both source-build and binary variants are available. Source AUR packages can trigger long local builds and heavy dependency downloads. Examples:

- Use `powershell-bin`, not `powershell`.
- Use `visual-studio-code-bin`, not a source build, when the binary package fits the task.

For package-manager ergonomics on personal machines, configure command-level sudoers entries so package installation does not block on a password prompt. Keep the scope limited to package-management binaries, not full sudo access:

```sudoers
spencer ALL=(ALL) NOPASSWD: /usr/bin/pacman
spencer ALL=(ALL) NOPASSWD: /usr/bin/paru
```

Avoid argument-pattern sudoers rules such as `/usr/bin/pacman -S *`; they are too brittle for sync, upgrade, reinstall, and dependency flows. Do not use `NOPASSWD: ALL`.
