# Windows Environment

This Windows setup uses `winget` for system tools when available and `scoop` only as a fallback. The setup script is interactive by default, with `-Yes` for a full recommended install and `-NonInteractive` for conservative defaults.

PATH updates made by the setup script are session-scoped unless a profile block is written. Open a new PowerShell session after setup to pick up profile changes.

## Windows Shell Defaults

On Windows, keep PowerShell ergonomic for Unix habits:

- `ls` -> `eza --icons=auto`
- `ll` -> `eza --icons=auto -la`
- `la` -> `eza --icons=auto -a`
- `bcat` -> `bat`; keep native `cat`/`Get-Content` semantics available for scripts
- `grep` -> `rg`
- `find` -> `fd`
- `du` -> `dust`
- `df` -> `duf`
- `pps` -> `procs`; keep native `ps`/`Get-Process` semantics available for scripts
- `top` -> `btm`
- `bdiff` -> `delta`; keep native `diff`/`Compare-Object` semantics available for scripts
- `rm` -> platform trash or recycle bin deletion, not permanent `Remove-Item`

Keep helper functions for `which`, `touch`, `open`, `head`, `tail`, `less`, `wc`, `uptime`, and `pkill` when working in PowerShell. Preserve `z`/zoxide as the preferred directory jumper when configured.

Do not enable Starship by default on this Windows profile. Its PowerShell initialization is too expensive for the current shell startup path.
