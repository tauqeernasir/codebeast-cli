# Agent Skills

[← Back to README](../README.md)

A skill is a reusable set of instructions: a review checklist, a release procedure,
your team's conventions. codebeast uses the [Agent Skills](https://agentskills.io/)
format, so skills written for other agents work here too.

Only each skill's name and description sit in the agent's context. The full instructions
load when the skill is used, so installing many skills costs little.

## Using skills

- The agent loads a skill on its own when the task matches its description.
- Run one yourself with `/<skill-name> [args]`.
- `/skills` lists installed skills. Press `space` to enable or disable one, `⏎` to run it.

Built-in skills:

| Skill | What it does |
| --- | --- |
| `/code-review` | Reviews the current changes and writes a report in the chat |
| `/init` | Scans the repo and proposes `AGENTS.md`, language servers and skills |

## Where skills live

| Scope | Location |
| --- | --- |
| Personal (all projects) | `~/.agents/skills/<name>/SKILL.md` or `~/.codebeast/skills/<name>/SKILL.md` |
| Project (commit with the repo) | `<repo>/.agents/skills/<name>/SKILL.md` or `<repo>/.codebeast/skills/<name>/SKILL.md` |

A project skill overrides a personal or built-in skill with the same name. In a monorepo,
the skill closest to your working directory wins.

## Writing a skill

Create a directory named after the skill, with a `SKILL.md` inside:

```
release-notes/
├── SKILL.md
└── references/style.md   # optional; read only when SKILL.md points to it
```

```markdown
---
name: release-notes
description: Draft release notes from merged PRs since the last tag. Use when the user asks for release notes or a changelog entry.
allowed-tools: [bash]
---

1. Find the last tag with `git describe --tags --abbrev=0`.
2. List merged PRs since then ...
3. Follow the tone in references/style.md.
```

Frontmatter:

| Field | Meaning |
| --- | --- |
| `name` | Required. Lowercase letters, digits and hyphens; must match the directory name |
| `description` | Required. What it does **and when to use it**. The agent only sees this until the skill loads |
| `when_to_use` | Extra hint about when to use it |
| `paths` | File globs that make the skill relevant, e.g. `["*.docx"]` |
| `allowed-tools` | Tools that skip the approval prompt while the skill is active |
| `disallowed-tools` | Tools blocked while the skill is active, e.g. `[write, edit]` for a review |
| `disable-model-invocation` | `true`: only you can run it, with `/<name>` |
| `user-invocable` | `false`: only the agent can use it |

Tips:

- The description decides when the skill is used. Say what it does and when.
- Keep `SKILL.md` short (under 500 lines). Put long reference material in
  `references/` and link to it.
- Your deny rules always win over `allowed-tools`.

## Configuration

```json
{
  "skills": {
    "enabled": true,
    "disableBundled": false,
    "disableSkillShellExecution": false,
    "only": [],
    "except": ["some-skill"]
  }
}
```

`only` is an allowlist and `except` a denylist (`except` wins). `--no-skills` turns skills
off for one run.
