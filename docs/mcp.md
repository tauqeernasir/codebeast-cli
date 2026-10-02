# MCP servers

[← Back to README](../README.md)

codebeast connects to [Model Context Protocol](https://modelcontextprotocol.io) servers
and gives their tools to the agent. A tool appears as `mcp__<server>__<tool>`.

## Adding a server

The quickest way is the manager: run `/mcp`, press `a`, and paste an `https://…` URL (a
remote server) or a command (a local server). Changes are saved to your config.

Or add servers to `codebeast.json`:

```json
{
  "mcp": {
    "enabled": true,
    "mcpServers": {
      "filesystem": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
      },
      "notion": {
        "type": "http",
        "url": "https://mcp.notion.com/mcp"
      },
      "internal": {
        "type": "http",
        "url": "https://mcp.example.com/mcp",
        "headers": { "Authorization": "Bearer ${INTERNAL_TOKEN}" }
      }
    }
  }
}
```

| Transport | Shape |
| --- | --- |
| stdio | `{ "command": "...", "args": [...], "env": { ... } }` |
| http | `{ "type": "http", "url": "...", "headers": { ... } }` |
| sse | `{ "type": "sse", "url": "..." }` |

`${VAR}` and `${VAR:-fallback}` are expanded in commands, args, env values, URLs and
headers.

In `/mcp`: `⏎` enables or disables a server (or signs in), `o` signs in again, `x` signs
out, `dd` removes a server.

## Signing in

Remote servers that need authorization (Notion, Linear, Sentry, …) sign in through your
browser. You don't need to copy a token. Add the server with just its URL. If it needs
sign-in, codebeast opens your browser, and you approve access there.

Over SSH or in a container, codebeast prints the URL instead. Open it, approve, and paste
the redirect URL back.

Tokens are stored in `~/.config/codebeast/mcp-auth.json` (mode `0600`), never in
`codebeast.json`, and refresh automatically.

From the shell:

```bash
codebeast mcp list             # servers and whether they need sign-in
codebeast mcp login <server>
codebeast mcp logout <server>
```

Single-prompt runs never open a browser. A server that needs sign-in is skipped with a
note.

A static `Authorization` header turns browser sign-in off for that server. So does
`"oauth": false`. For servers without dynamic client registration, pass a registered
client:

```json
"oauth": { "clientId": "my-client", "clientSecret": "{env:MCP_SECRET}", "scopes": ["read"] }
```

## Safety

- Every MCP tool asks for approval by default.
- `"trusted": true` on a server lets its read-only tools (those marked `readOnlyHint`) run
  without asking.
- `"autoApprove": ["tool_name"]` pre-approves specific tools.
- Your deny rules always win.

MCP tools are not available in Plan mode.
