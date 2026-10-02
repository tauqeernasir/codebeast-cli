# Getting started

[← Back to README](../README.md)

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/tauqeernasir/codebeast-cli/main/install.sh | bash
```

The installer downloads the binary for your OS and CPU from
[Releases](https://github.com/tauqeernasir/codebeast-cli/releases) and installs it to
`~/.local/bin/codebeast`. It does not use `sudo`, so the directory must be writable. No
runtime (Node, Bun, Python) is needed.

Options, set as environment variables:

| Variable | Default | Meaning |
| --- | --- | --- |
| `CODEBEAST_VERSION` | `latest` | Release tag to install, e.g. `v0.1.2` |
| `CODEBEAST_INSTALL_DIR` | `~/.local/bin` | Where to put the binary |

```bash
curl -fsSL https://raw.githubusercontent.com/tauqeernasir/codebeast-cli/main/install.sh \
  | CODEBEAST_VERSION=v0.1.2 CODEBEAST_INSTALL_DIR="$HOME/bin" bash
```

**Manual download.** Download `codebeast-<os>-<arch>.tar.gz` from the latest release
(`darwin-arm64`, `darwin-x64`, `linux-x64` or `linux-arm64`), check it against
`SHA256SUMS`, extract it, and put `codebeast` on your `PATH`.

**Linux sandbox.** Shell commands run in an OS sandbox. On Linux it needs `bubblewrap`
and `socat`:

```bash
sudo apt-get install bubblewrap socat
```

## First run

Run `codebeast` in a project directory. A fresh install opens the setup wizard:

1. **Pick a provider.** Detected options are listed first: a running Ollama or LM Studio
   server, or an exported key such as `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`,
   `OPENROUTER_API_KEY` or `GEMINI_API_KEY`. Presets cover OpenAI, Anthropic, OpenRouter,
   Google Gemini, DeepSeek, Groq, Mistral, xAI, Together AI, Ollama and LM Studio.
   **Custom endpoint** takes any OpenAI-compatible URL (vLLM, LiteLLM, a company proxy).
2. **Enter your API key.** The input is masked. Type `{env:MY_VAR}` to read the key from
   an environment variable instead of storing it.
3. **Connection check.** codebeast calls the provider's `/models` endpoint and tells you
   what to fix if it fails: a rejected key, a wrong URL, or a server that isn't running.
4. **Choose a default model.** Type to filter. Switch any time with `/models`.

The wizard saves the provider to `~/.codebeast/codebeast.json`. The key itself goes to
`~/.config/codebeast/auth.json` (readable only by you), so the config file is safe to
share.

To add another provider later, run `/connect` in the app, or `codebeast setup` from the
shell. To configure providers by hand, see [Configuration](configuration.md).

## Set up a project

Run this once in each repository:

```bash
codebeast init
```

(or `/init` inside the app). It scans the stack, proposes an `AGENTS.md` with your build,
test and lint commands and conventions, and suggests language servers and skills.
codebeast loads `AGENTS.md` into every session, so the agent knows how your project
works.

## Ways to run it

| Command | What it does |
| --- | --- |
| `codebeast` | Interactive app |
| `codebeast "task"` or `codebeast -p "task"` | Run one task and print the result, no UI |
| `codebeast init` | Set up the current repo |
| `codebeast setup` | Add a provider, then exit |
| `codebeast --list-models` | List models from your providers |
| `codebeast --version` | Print the installed version |
| `codebeast acp` | Serve editors over the Agent Client Protocol ([Editors](editors.md)) |
| `codebeast watch` | Work on assigned GitHub issues and review requests ([GitHub](github.md)) |
| `codebeast mcp list` | Show MCP servers ([MCP](mcp.md)) |

Single-prompt runs never stop to ask. Safe commands and edits inside the project run;
everything else is denied with a message. See [Permissions](permissions.md).

## Update

Run the install command again. It replaces the binary with the latest release. Check
which version you have with `codebeast --version`.

## Uninstall

```bash
rm ~/.local/bin/codebeast
```

To also remove settings, saved sessions and stored keys:

```bash
rm -rf ~/.codebeast ~/.config/codebeast
```

Project files that codebeast may have created (`AGENTS.md`, `.codebeast/`,
`codebeast.json`) stay in your repositories until you delete them.
