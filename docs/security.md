# Security Notes

This setup can install tools and write agent instruction files. Treat it like any other developer bootstrap script.

Remote bootstrap usage such as:

```powershell
irm https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.ps1 | iex
```

downloads and executes PowerShell code from GitHub. Review `install.ps1`, `setup-windows.ps1`, and the rule fragments before running it on a machine you care about.

Linux bootstrap usage such as:

```bash
curl -fsSL https://raw.githubusercontent.com/NihilDigit/coding-agents-setup/main/install.sh | bash
```

downloads a repository archive and runs `setup-linux.sh`. By default the bootstrap downloads the commit from the latest successful smoke-test run triggered by a `ci-*` tag; branch testing requires an explicit `REF`/`REF_KIND` override. The Linux setup writes agent Markdown files and user-local helpers such as `~/.local/bin/clip-run`; it does not install system packages or edit shell profiles.

Persistent files overwritten by setup are backed up first. Linux writes adjacent `*.bak-<timestamp>` files for agent rules and `clip-run`. Windows writes backups under `~/.coding-agents-backup-<timestamp>` before replacing agent rules, PowerShell profiles, setup selection state, or `rtk.exe`; existing Claude skills links/directories are moved aside with an `.old-<timestamp>` suffix.

The Kimi WebBridge installer uses the vendor's current PowerShell installer:

```powershell
irm https://cdn.kimi.com/webbridge/install.ps1 | iex
```

The setup script keeps this behind an explicit prompt with default yes and prints a warning before running it.

Agent Skills installed with `bunx skills add <repo>` are also downloaded from GitHub repositories. Review the repository URLs before installing skills on untrusted networks.
