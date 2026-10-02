# Using codebeast

[← Back to README](../README.md)

## Modes

Press `Tab` to switch between the two modes. The conversation carries over.

- **Agent** (default): reads, edits, runs commands, and uses every enabled tool.
- **Plan**: read-only. The agent investigates and submits a plan. The plan opens in a
  side pane and is saved to `.codebeast/plans/`. Reply with **Build** (`b`) to approve it
  and switch to Agent, **Edit** (`e`) to change it yourself, or **Request changes** (`r`).
  After Build, the plan's steps become a checklist that ticks off as the agent works.

`Shift+Tab` cycles the approval mode: **auto-edit** (default), **ask**, and **allow all**.
See [Permissions](permissions.md).

## Writing prompts

- `@` references a file. The menu is fuzzy.
- `/` opens slash commands.
- `Shift+Enter` adds a new line.
- `↑` / `↓` recall earlier prompts.
- Paste an image with `Cmd/Ctrl+V`. Vision models see it; text-only models get a note.
- Press Enter while the agent works to queue a message. Queued messages are sent in order
  when the turn ends.
- `Esc` interrupts. Press it twice to stop the run.

## Keyboard shortcuts

| Key | Action |
| --- | --- |
| `Tab` | Switch Agent ⇄ Plan |
| `Shift+Tab` | Cycle approval mode |
| `Ctrl+K` | Command palette |
| `Ctrl+T` | Cycle reasoning effort |
| `Ctrl+E` | Focus mode (one line per step) |
| `Ctrl+B` | Toggle the side panel (plan, background jobs, context) |
| `Ctrl+O` | Toggle the plan pane |
| `Ctrl+G` | Watch sub-agents |
| ``Ctrl+` `` | Terminals |
| `Ctrl+Shift+R` | Review changes |
| `Ctrl+R` | Resume the latest session (home screen) |
| `PgUp` / `PgDn` | Scroll the transcript |
| `F1` | Help |

When the agent asks for approval: `y` allow once, `a` always allow, `s` allow everything
this session, `n` deny. Answer questions with `1`–`9`.

## Slash commands

| Command | What it does |
| --- | --- |
| `/new` | Start a new session |
| `/sessions` | Browse and resume sessions for this project (`/sessions all` for every project) |
| `/fork` | Copy this session and keep working in the copy |
| `/compact` | Summarize older history to free context |
| `/models` | Switch model |
| `/connect` | Add a model provider |
| `/init` | Scan the repo and propose `AGENTS.md` |
| `/review` | Review uncommitted changes |
| `/reviews` | List saved reviews |
| `/commit [message]` | Pick files, preview the message, commit |
| `/pr [hint]` | Commit if needed, push, and open or reuse a GitHub PR |
| `/skills` | List, enable or disable skills ([Skills](skills.md)) |
| `/mcp` | Manage MCP servers ([MCP](mcp.md)) |
| `/connectors` | Connect GitHub ([GitHub](github.md)) |
| `/agents` | Configure sub-agents |
| `/tasks` | Open the sub-agent viewer |
| `/terminals` | Open the terminal viewer |
| `/browser` | Show the browser session |
| `/approval` | Show or switch the approval mode |
| `/sandbox [on\|off]` | Show or toggle the shell sandbox for this session |
| `/notify [on\|off]` | Toggle notifications for this session |
| `/focus` | Toggle focus mode |
| `/theme` | Pick a color theme |
| `/mouse` | Toggle mouse capture (turn off to select text natively) |
| `/help` | Shortcuts and tips |
| `/exit` | Quit |

Any installed skill can also be run as `/<skill-name> [args]`.

## Sessions

Sessions save automatically and are listed per project. Resume one with `/sessions`, or
`Ctrl+R` on the home screen for the latest. Long sessions compact automatically: older
turns become a summary and recent turns stay as they were.

## Sub-agents

For research that would fill the conversation, the agent starts a sub-agent with its own
context and gets back a short report. There are three built-in profiles:

- **explorer**: maps code and reads docs. Read-only.
- **debugger**: reproduces and root-causes problems with the shell, terminals and the
  browser.
- **reviewer**: critiques a diff.

Up to three run at once. Watch them live with `Ctrl+G`. Use `/agents` to give a profile its
own model, tools or MCP servers, or to add your own profiles.

## Terminals and the browser

The agent can keep **persistent terminals**: shells where `cd`, environment variables and
virtualenvs persist across turns, and where it can type into prompts. Open the viewer with
``Ctrl+` ``.

The agent can drive a **headless Chrome** to check a running app: click, fill forms,
read console errors, take screenshots. It needs Playwright, installed once in
`~/.codebeast` (or in your project's `node_modules`):

```bash
mkdir -p ~/.codebeast && cd ~/.codebeast && npm install playwright && npx playwright install chrome
```

With Bun, use `bun add playwright && bunx playwright install chrome` instead.

Each new site asks for approval the first time. To skip the prompt for local dev servers,
add `"browser": { "allowedOrigins": ["http://localhost:*"] }` to your config.

## Reviewing changes

`/review` (or `Ctrl+Shift+R`) opens a review of your uncommitted changes: staged,
unstaged and new files, whoever made them.

- Browse files in the sidebar and leave comments on lines.
- Press `r` to run a reviewer agent. It posts findings on the lines they concern and gives
  a verdict. Press `r` again after you make fixes: the follow-up checks the earlier
  findings and reviews only what changed.
- `Ctrl+Enter` sends your open comments to the main agent to fix.
- `C` / `P` open the commit / PR preview with the reviewed files selected.

Reviews are stored inside `.git`, so they are never committed.

For a written report in the chat instead, run `/code-review`.

## Commits and pull requests

`/commit` shows the changed files and a drafted message. Choose files, edit the message,
and confirm. `/pr` also pushes and opens a GitHub pull request, or updates the open one for
the branch. codebeast never amends, skips hooks, or force-pushes.

## Images

On a vision model, the agent can look at image files, browser screenshots and images
returned by MCP tools. `/models` and `--list-models` mark which models accept images.

## Notifications

codebeast notifies you when a turn finishes, needs your input, or fails. It stays quiet
while the terminal is focused or you typed in the last 30 seconds. It uses OS
notifications, terminal notifications (iTerm2, kitty, WezTerm), and the terminal bell.
Turn notifications off with `/notify off`, `--no-notify`, or `"notifications": { "enabled": false }`.
