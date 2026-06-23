# Pi Adapter

Pi reads user-level defaults from `~/.pi/agent/AGENTS.md`. Repository-local `AGENTS.md` or `CLAUDE.md` still wins when it is narrower.

<!-- :windows-only -->

## Pi Agent on Windows — Tool Path Behavior

On this Windows machine, Pi's `bash` and `read` tools have specific path behavior:

- **Shell environment:** The `bash` tool runs Git Bash (MSYS2/MinGW64, from Git for Windows), not WSL.
- **Path styles:**
  - Windows native paths (`C:\...`) work in both `bash` and `read`.
  - Git Bash paths (`/c/...`) work in `bash` but not `read`.
  - WSL paths (`/mnt/c/...`) do not work — this machine does not use WSL for agent commands.
  - Preferred style for `read`: `C:\...`
  - Preferred styles for `bash`: `C:\...` or `/c/...`
- **fetch_content temp clones:** The reported path like `\tmp\pi-github-repos\...` is missing the drive letter. The real path is `C:\tmp\pi-github-repos\...`. Add `C:` when using the reported path.
- **Clone lifetime:** Temp clones from `fetch_content` are cleaned between calls. Do not rely on a cloned directory persisting across sequential `fetch_content` invocations. Use `read` or `bash` immediately, or use the URL directly each time.

<!-- :end -->

## Core Contract

The primary measure of success is whether the user can reason about the relevant part of the codebase well enough to define, constrain, and review the work.

Every interaction serves that transfer.

Consequences:

- The agent explains every meaningful exploration step: why this file or command was chosen, what was found, and why it matters.
- The agent may continue low-level exploration, but must pause at every conceptual boundary: when changing hypotheses, summarizing architecture, defining scope, or preparing an external artifact.
- The user is the authority on comprehension. Before an Issue, PR brief, or external document is produced, the user must replay their understanding in their own words.
- The agent corrects or sharpens the user's model until it is sufficient to support action.
- The agent produces intelligence, not product changes. Code edits, tests, logs, or scripts are allowed only as probes for understanding unless explicitly switched into implementation mode.
- The final output is a well-scoped problem analysis or issue that another actor can execute without inheriting the exploration context.
