# Editors and orchestrators (ACP)

[← Back to README](../README.md)

`codebeast acp` speaks the [Agent Client Protocol](https://agentclientprotocol.com) over
stdio. Editors and orchestration tools run it as a subprocess. You get the same agent as
in the terminal app, with the same config, tools, sandbox, permissions and saved
sessions.

## Set up your editor

GUI apps often don't see your shell's `PATH`, so use the absolute path to the binary
(`which codebeast`, usually `~/.local/bin/codebeast`).

**Zed** — `~/.config/zed/settings.json`:

```jsonc
"agent_servers": {
  "codebeast": {
    "type": "custom",
    "command": "/Users/<you>/.local/bin/codebeast",
    "args": ["acp"]
  }
}
```

**JetBrains IDEs** — add the same `command` and `args` to `~/.jetbrains/acp.json`.

**acpx** — `~/.acpx/config.json`:

```json
{ "agents": { "codebeast": { "command": "codebeast", "args": ["acp"] } } }
```

```bash
npx -y acpx codebeast exec "summarize this repo"
```

**Neovim, Emacs and others** — any ACP client works. Point it at `codebeast acp`.

## First run

If no model is configured yet, the editor offers **Set up codebeast**. That opens the
setup wizard in a terminal; when you finish, the editor retries. You can also run
`codebeast setup` yourself beforehand.

For headless use, set `CODEBEAST_API_KEY` (plus `CODEBEAST_BASE_URL` for providers other
than OpenAI) in the environment of the `codebeast acp` process.

## What works

- New, loaded and resumed sessions. ACP sessions also show up in `/sessions` in the
  terminal app.
- Streaming replies, reasoning, tool calls with diffs, live command output, and the plan.
- Approval prompts in the editor: allow once, always, all this session, or deny.
- Agent / Plan mode, model, reasoning level and approval mode as session options.
- Skills as slash commands, plus `/compact`.
- Images in prompts (vision models).
- MCP servers passed by the editor (used for that session only, and every tool asks).
- Unsaved editor buffers: reads and edits go through the editor when it supports this.

Not supported yet: audio prompts and session forks.

## Configuration

The `acp` block in `codebeast.json`:

| Key | Default | Meaning |
| --- | --- | --- |
| `approval` | `auto-edit` | Approval mode for new sessions: `ask`, `auto-edit` or `allow-all` |
| `delegateFs` | `auto` | Read and write files through the editor when offered; `never` keeps it local |
| `delegateTerminal` | `never` | `auto` runs commands in the editor's terminal (only while the sandbox is off) |
| `includeConfiguredMcp` | `true` | Also load MCP servers from your config |
| `maxSessions` | `8` | Open sessions per process |
| `saveSessions` | `true` | Save sessions with the rest of your history |

Each key also has an environment variable: `CODEBEAST_ACP_APPROVAL`,
`CODEBEAST_ACP_SAVE_SESSIONS`, and so on. `CODEBEAST_LOG_LEVEL` (`error`, `warn`, `info`,
`debug`) controls the log on stderr.

## Orchestrators

- **Unattended runs:** set `CODEBEAST_ACP_APPROVAL=allow-all`. Your deny rules still apply.
- **Throwaway runs:** set `CODEBEAST_ACP_SAVE_SESSIONS=false`.
- **Parallel agents:** run one process per git worktree.

## Limitations

- No Windows build yet.
- MCP servers that need browser sign-in are skipped. Sign in first with
  `codebeast mcp login <server>`.
- One process can serve several projects, but not projects with different `sandbox`
  settings. Start a separate process for those.
