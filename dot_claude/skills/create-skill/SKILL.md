---
name: create-skill
description: Create a new Claude Code skill. Use when the user wants to create a new skill, slash command as a skill, or automate a repeatable workflow via skills.
argument-hint: [skill-name]
---

Create a new global skill at `~/.claude/skills/$ARGUMENTS/SKILL.md`.

## Steps

1. Create the directory `~/.claude/skills/$ARGUMENTS/`
2. Write `SKILL.md` with appropriate frontmatter and instructions
3. Confirm the file was created

## SKILL.md format

```markdown
---
name: <skill-name>                  # lowercase, hyphens only, max 64 chars
description: <what it does and when to use it>  # combined with when_to_use, max 1536 chars
when_to_use: <trigger phrases or examples>       # optional
argument-hint: [arg1] [arg2]        # optional, shown in autocomplete
arguments: [arg1, arg2]             # optional, enables $0/$1/$name substitution
disable-model-invocation: true      # optional, user-invoked only (hides from Claude auto-trigger)
user-invocable: false               # optional, Claude-only (hides from / menu)
allowed-tools: Bash Read Edit       # optional, tools allowed without permission prompt
context: fork                       # optional, runs in isolated subagent
agent: Explore                      # optional, subagent type when context: fork
effort: low|medium|high|xhigh|max  # optional, overrides session effort level
paths: src/**/*.ts                  # optional, glob to limit when skill activates
---

<instructions for Claude>
```

## Key design decisions to ask the user about

- **Invocation**: Should Claude invoke automatically, or user-only (`disable-model-invocation: true`)?
- **Arguments**: Does it need dynamic input via `$0`, `$1`, or named args?
- **Isolation**: Should it run in a subagent (`context: fork`)?
- **Tools**: Any tools that should be pre-approved?

## Variable substitutions

| Variable | Meaning |
|----------|---------|
| `$ARGUMENTS` | All arguments as a string |
| `$0`, `$1`, ... | Positional arguments |
| `$name` | Named argument from `arguments` field |
| `${CLAUDE_SKILL_DIR}` | Directory containing SKILL.md |
| `` !`command` `` | Shell output injected before Claude sees the skill |
