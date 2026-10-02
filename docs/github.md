# GitHub

[← Back to README](../README.md)

With GitHub connected, the agent can read and work on issues and pull requests, and
`codebeast watch` can review PRs and implement issues without you at the keyboard.

`/commit` and `/pr` use your local `git` and a GitHub token. See
[Using codebeast](usage.md#commits-and-pull-requests).

## Connect

Run `/connectors`, select GitHub, and paste a personal access token. codebeast also picks
up a token automatically, in this order:

1. `connectors.github.token` in config (use `{env:VAR}` or `{file:path}`)
2. The token saved by `/connectors` (`~/.config/codebeast/connectors.json`, mode `0600`)
3. `GITHUB_TOKEN`, then `GH_TOKEN`
4. `gh auth token`, if the GitHub CLI is signed in

Token scopes: a classic token needs `repo` (or `public_repo` for public repos only). A
fine-grained token needs **Issues** and **Pull requests** read/write on your repos.

## Tools

`owner` and `repo` default to your `origin` remote.

| Reads (run without asking) | Writes (ask first) |
| --- | --- |
| List and get issues | Create, update and comment on issues |
| List and get pull requests, files, reviews | Create, update and merge pull requests |
| PR status: mergeability and CI checks | Inline review comments, submit reviews |
| | Request reviewers |

Read tools also work in Plan mode and in sub-agents.

## Reviews from a bot account (optional)

To post reviews as `your-app[bot]` instead of yourself, register your own GitHub App:

1. GitHub → Settings → Developer settings → GitHub Apps → **New GitHub App**. A ready
   manifest is in [`examples/github-app-manifest.json`](../examples/github-app-manifest.json).
2. Permissions: **Pull requests** read/write, **Issues** read/write, **Checks** write,
   **Contents** read, **Metadata** read. Leave webhooks off. (The manifest grants
   **Contents** write, which is only needed if the App should push.)
3. Generate a private key and store it outside git, e.g.
   `~/.config/codebeast/github-app.pem` (`chmod 600`).
4. Install the App on your repositories.
5. In `/connectors`, select GitHub and press `a`, or add it to config:

```json
{
  "connectors": {
    "github": {
      "token": "{env:GITHUB_TOKEN}",
      "app": {
        "id": "{env:GITHUB_APP_ID}",
        "privateKey": "{file:~/.config/codebeast/github-app.pem}"
      }
    }
  }
}
```

Reviews and review comments then post as the App. `/pr`, issues and creating PRs stay on
your personal token. Because you push and the bot reviews, the bot can approve your PRs
(unless your org blocks Apps from approving).

## codebeast watch

`codebeast watch` picks up work on GitHub and runs it, one job at a time:

- **Issues** assigned to you (or to the bot): codebeast implements them and opens a PR.
- **Pull requests** that request you (or the bot) as a reviewer: codebeast reviews them.
- Anything labeled `codebeast:review`.

```bash
codebeast watch              # poll every 15 minutes
codebeast watch --once       # one pass, then exit (cron, CI)
codebeast watch --dry-run    # show what it would pick up
codebeast watch --install    # run as a launchd / systemd service
codebeast watch --uninstall
```

Watch jobs run unattended. Edits, GitHub tools and sandboxed commands are allowed. Watch
never merges PRs, force-pushes or hard-resets, and review jobs only comment, never edit.
Your own deny rules still apply.

```json
{
  "watch": {
    "interval": "15m",
    "assignee": "@me",
    "label": "codebeast:review",
    "repos": [{ "repo": "owner/name", "path": "~/src/name" }],
    "issues": { "enabled": true },
    "reviews": { "enabled": true, "skipDrafts": true, "skipOwnPrs": true }
  }
}
```

### Run it in GitHub Actions

You don't need a machine left on. Copy
[`examples/workflows/codebeast-watch.yml`](../examples/workflows/codebeast-watch.yml) into
`.github/workflows/` in your repo and add these repository secrets:

- `CODEBEAST_API_KEY`, and `CODEBEAST_BASE_URL` if your provider isn't OpenAI
- `GITHUB_APP_ID` and `GITHUB_APP_PRIVATE_KEY` (optional; for bot reviews)

Then request the App as a reviewer on a PR, or add the `codebeast:review` label. The
workflow also runs every 15 minutes to catch anything missed.
