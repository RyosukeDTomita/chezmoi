@AGENTS.md

## Claude-specific Conventions

### Skill/Command File Locations

- Project skills go in `.claude/skills/<name>/SKILL.md` (NOT `.claude/commands/` or `~/.claude/`)
- Use `CLAUDE_SKILL_DIR` for path resolution in skill scripts, not absolute paths or hardcoded relative depths
