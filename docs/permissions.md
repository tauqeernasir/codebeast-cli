# Permissions and sandbox

[← Back to README](../README.md)

Every tool call is checked before it runs. The result is **allow**, **ask** or **deny**.

## What runs without asking

| Kind | Default |
| --- | --- |
| Reading and searching files | Allowed |
| Editing files inside the project | Allowed (in **auto-edit** mode) |
| Editing files outside the project | Asks |
| Shell commands | Depends on risk (below) |
| Web fetch, sub-agents, new terminals, the browser, MCP tools, GitHub write actions | Asks |

codebeast parses each shell command and rates it:

- **Low risk, runs:** reads, builds, tests, linters, package scripts, lockfile installs,
  `git add` / `commit` / `switch` / `pull`, deleting build output.
- **Medium risk, asks:** unknown programs, network access, writes outside the project, new
  dependencies, `git push`, reading secrets such as `.env`. Inside the sandbox these run
  without asking (except secret reads).
- **High risk, always asks:** broad deletes (`rm -rf ~`), history rewrites
  (`reset --hard`, force-push), `sudo`, `curl … | sh`, editing shell startup files,
  publishing packages. An allow rule cannot skip these.

## Answering a prompt

| Key | Choice |
| --- | --- |
| `y` | Allow once |
| `a` | Always allow. Saved to `~/.codebeast/permissions.json`. Shell commands are remembered by prefix, e.g. `git push` |
| `s` | Allow everything for the rest of this session (not saved) |
| `n` | Deny. The agent is told and continues |

## Approval modes

`Shift+Tab` (or `/approval`) switches how the session asks:

| Mode | Behavior |
| --- | --- |
| **auto-edit** (default) | Project edits and low-risk commands run; the rest asks |
| **ask** | Edits ask too |
| **allow all** | Nothing asks for this session. Your deny rules still apply |

`--dangerously-skip-permissions` turns all checks off, including deny rules. Use it only in
throwaway environments.

Single-prompt runs (`codebeast -p`) cannot ask. Anything that would ask is denied.

## Shell sandbox

Shell commands and terminals run inside an OS sandbox: Seatbelt on macOS, bubblewrap on
Linux (install `bubblewrap` and `socat`).

- **Writes** are limited to the project, temp directories, `~/.codebeast`, and existing
  package-manager caches.
- **Network** is limited to an allowlist of package registries and Git hosts. Local ports
  work, so dev servers and test browsers can start.
- **Credentials** such as `~/.ssh` and `~/.aws` can't be read. Writing to `.env` and
  `.git/hooks` is blocked.

If a legitimate command is blocked, the agent can ask to run it once outside the sandbox.
You always get a prompt for that. `docker` and `sudo` always run outside the sandbox and
always ask.

`/sandbox` shows the status. `/sandbox off` and `/sandbox on` toggle it for the current
session.

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllow": true,
    "failIfUnavailable": false,
    "filesystem": { "allowWrite": ["~/.cache/my-tool"] },
    "network": { "allowedDomains": ["api.example.com"] }
  }
}
```

| Key | Meaning |
| --- | --- |
| `enabled` | Use the sandbox when the OS supports it |
| `autoAllow` | Run sandboxed commands without asking |
| `failIfUnavailable` | Refuse to run commands if the sandbox can't start |
| `allowUnsandboxedCommands` | Allow the "run once outside the sandbox" request |
| `filesystem.allowWrite` | Extra writable paths |
| `network.allowedDomains` | Extra domains, added to the built-in list |

## Rules

Add your own rules under `permissions.rules`. Each rule matches by `category`, `tool`, or
a shell command `pattern` (glob), and sets `decision` to `allow`, `ask` or `deny`. Deny
rules are checked first and always win.

```json
{
  "permissions": {
    "rules": [
      { "category": "bash", "pattern": "terraform apply*", "decision": "deny", "reason": "Use CI" },
      { "category": "bash", "pattern": "make deploy-staging", "decision": "allow" },
      { "category": "network", "decision": "allow" }
    ]
  }
}
```

Categories: `readonly`, `write`, `bash`, `network`, `terminal`, `browser`, `subagent`,
`mcp`, `connector`. Use `category: "bash"` with a `pattern` so the rule covers both
one-off commands and persistent terminals. An allow rule never unlocks a high-risk command.

## Audit log

Every tool call is logged to `~/.codebeast/audit.log`, one JSON line each: time, session,
tool, risk, decision, and outcome.
