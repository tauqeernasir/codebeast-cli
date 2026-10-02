# Configuration

[← Back to README](../README.md)

Most people never edit config by hand: the setup wizard (`/connect` or `codebeast setup`)
writes it for you. This page covers what you can set when you need to.

## Config files

codebeast merges these files, lowest to highest priority:

1. `~/.codebeast.json`
2. `~/.codebeast/codebeast.json` (the setup wizard writes here)
3. `~/.config/codebeast.json`
4. `./.codebeast.json` (project)
5. `./codebeast.json` (project)

Nested objects merge, so a project file that only sets `lsp` still uses your global
providers. Overall precedence: **CLI flags > config files > environment variables >
defaults**.

Add `"$schema"` to get completion and validation in your editor:

```json
{ "$schema": "https://raw.githubusercontent.com/tauqeernasir/codebeast-cli/main/codebeast.schema.json" }
```

> Do not commit API keys. Use one of the key references below and keep
> `codebeast.json` out of git if it holds anything private.

## Providers

Any OpenAI-compatible API works. Define providers under `providers` and pick the startup
model with `model` (`provider/model`):

```json
{
  "model": "openai/gpt-4o",
  "providers": {
    "openai": {
      "baseURL": "https://api.openai.com/v1",
      "apiKey": "{env:OPENAI_API_KEY}"
    },
    "ollama": {
      "baseURL": "http://localhost:11434/v1",
      "apiKey": ""
    }
  }
}
```

Models are discovered from each provider's `GET /models`. Provider fields:

| Field | Meaning |
| --- | --- |
| `baseURL` | API base URL (required) |
| `apiKey` | Key or key reference (required; `""` for local servers) |
| `models` | Extra model ids to offer, added to the discovered list |
| `reasonModels` | Model ids or globs that accept a reasoning-effort setting |
| `contextWindows` | Context window per model id or glob (see below) |
| `vision` | Whether a model accepts images, per model id or glob |
| `toolImages` | `user-message` (default) or `inline`: where tool images are sent |

With no `providers` block, `CODEBEAST_API_KEY` and `CODEBEAST_BASE_URL` (defaults to
OpenAI) define a single provider. This is handy in CI.

### API keys

`apiKey` accepts:

| Value | Read from |
| --- | --- |
| `{env:OPENAI_API_KEY}` | An environment variable |
| `{file:~/.secrets/openai}` | A file |
| `{auth}` | `~/.config/codebeast/auth.json`, written by the setup wizard (mode `0600`) |
| `sk-...` | Plain text. Works, with a warning |

## Models

- `codebeast --list-models` lists every model from every provider.
- `--model provider/model` (or a bare id) picks the startup model for one run.
- `/models` switches models in the app. `Ctrl+T` cycles reasoning effort
  (`low` / `medium` / `high`) on models that support it.

### Context window

codebeast detects each model's context window. It uses the first match from:
`contextWindows` in config → what the provider reports in `/models` → a built-in catalog
of popular models → `contextWindowTokens` → 128k. Set a value only when detection is
wrong:

```json
"providers": {
  "ollama": {
    "baseURL": "http://localhost:11434/v1",
    "apiKey": "",
    "contextWindows": { "qwen3-coder:30b": 65536, "*": 32768 }
  }
}
```

When the conversation reaches `compactionThreshold` (default `0.7`) of the window, older
turns are summarized. The last `preserveTurns` (default `3`) prompts stay as they were.

### Vision

Whether a model accepts images comes from `vision` in config, then provider metadata, then
the model name. Override it per model:

```json
"vision": { "qwen3-vl-*": true, "qwen3-coder": false }
```

## Common settings

| Config key | CLI flag | Env var | Default |
| --- | --- | --- | --- |
| `model` | `--model` | | first available |
| `temperature` | `--temperature` | `CODEBEAST_TEMPERATURE` | `0.2` |
| `maxTokens` | `--max-tokens` | `CODEBEAST_MAX_TOKENS` | `16000` (response tokens) |
| `maxTurns` | `--max-turns` | `CODEBEAST_MAX_TURNS` | `250` |
| `reasoningEffort` | | `CODEBEAST_REASONING_EFFORT` | |
| `contextWindowTokens` | `--context-window` | `CODEBEAST_CONTEXT_WINDOW_TOKENS` | `128000` (fallback only) |
| `compactionThreshold` | `--compaction-threshold` | `CODEBEAST_COMPACTION_THRESHOLD` | `0.7` |
| `preserveTurns` | `--preserve-turns` | `CODEBEAST_PRESERVE_TURNS` | `3` |
| `promptCacheRetention` | `--prompt-cache-retention` | `CODEBEAST_PROMPT_CACHE_RETENTION` | `in_memory` (or `24h`) |
| `retry.maxRetries` | | `CODEBEAST_RETRY_MAX_RETRIES` | `2` |
| `retry.baseDelayMs` | | `CODEBEAST_RETRY_BASE_DELAY_MS` | `1000` |
| `retry.maxDelayMs` | | `CODEBEAST_RETRY_MAX_DELAY_MS` | `30000` |

Other flags: `--dangerously-skip-permissions`, `--no-skills`, `--no-notify`,
`--version`. Run
`codebeast --help` for the full list.

## Feature blocks

Each feature has its own block. The details are on its page.

| Block | Page |
| --- | --- |
| `permissions`, `sandbox` | [Permissions and sandbox](permissions.md) |
| `skills` | [Agent Skills](skills.md) |
| `mcp` | [MCP servers](mcp.md) |
| `connectors`, `watch` | [GitHub](github.md) |
| `acp` | [Editors](editors.md) |

Smaller blocks:

```json
{
  "agents": {
    "enabled": true,
    "maxConcurrent": 3,
    "profiles": {
      "explorer": { "model": "openai/gpt-4o-mini" },
      "debugger": { "maxTurns": 80 }
    }
  },
  "browser": {
    "enabled": true,
    "headless": true,
    "channel": "chrome",
    "allowedOrigins": ["http://localhost:*", "http://127.0.0.1:*"]
  },
  "lsp": {
    "enabled": true,
    "servers": {
      "typescript": {
        "command": "typescript-language-server",
        "args": ["--stdio"],
        "languages": ["typescript", "javascript"],
        "rootMarkers": ["tsconfig.json", "package.json"]
      }
    }
  },
  "notifications": {
    "enabled": true,
    "osNotifications": true,
    "terminalNotifications": true,
    "sound": false,
    "bell": true,
    "suppressWhenFocused": true
  }
}
```

- **agents**: sub-agent limits and per-profile overrides (`model`, `tools`, `mcp`,
  `maxTurns`, `prompt`). `/agents` edits these for you.
- **browser**: the agent's headless Chrome. `allowedOrigins` skips the approval prompt for
  matching sites.
- **lsp**: language servers give the agent diagnostics, go-to-definition and references.
  Off by default; `/init` suggests servers for your stack and turns it on.
- **notifications**: alerts when a turn ends or needs you.

## Project instructions

codebeast loads `AGENTS.md` from your repository root down to the current directory. A
file closer to where you run codebeast takes precedence. `AGENTS.override.md` replaces
`AGENTS.md` in the same directory. Use it for build commands, conventions, and anything
the agent should always know. Set `"respectProjectInstructions": false` to turn this off.

## Files codebeast writes

| Path | Contents |
| --- | --- |
| `~/.codebeast/codebeast.json` | Config written by the setup wizard |
| `~/.config/codebeast/auth.json` | Provider keys from the wizard (`0600`) |
| `~/.config/codebeast/connectors.json` | GitHub token (`0600`) |
| `~/.config/codebeast/mcp-auth.json` | MCP sign-in tokens (`0600`) |
| `~/.codebeast/permissions.json` | Your "always allow" choices |
| `~/.codebeast/audit.log` | One line per tool call and its permission decision |
| `~/.codebeast/sessions/` | Saved sessions |
| `~/.codebeast/tui.json` | Theme and layout preferences |
| `<repo>/.codebeast/plans/` | Saved plans (add to `.gitignore` if you don't want them committed) |
