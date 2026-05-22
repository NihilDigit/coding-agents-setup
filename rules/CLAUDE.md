# Claude Code Adapter

Claude Code reads user-level defaults from `~/.claude/CLAUDE.md`. Repository-local `CLAUDE.md` still wins when it is narrower.

Keep user-installed skills in `~/.agents/skills`. Expose them to Claude Code through `~/.claude/skills` as a symlink or junction.

Use `~/.claude/agents` for Claude-specific subagents when needed. Do not enable hooks or MCP servers by default; configure them only when the task or project explicitly calls for them.
