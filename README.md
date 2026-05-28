# ai-box

A Docker-based SSH development environment with AI coding tools pre-installed.

## Quick start

```bash
cp .env.example .env
# edit .env with your keys
make build
ssh dev@localhost -p 2222
```

Once inside, run `agent` to start or attach to a tmux session.

## What's inside

- **SSH** — key-based auth only, port 2222 → 22
- **Node.js 22** + **opencode-ai** — AI coding assistant
- **gh CLI** — authenticated via `GITHUB_TOKEN` from `.env`, git over HTTPS
- **vim** — 10 plugins (JS, JSON, Markdown, Dockerfile syntax; fugitive, commentary, surround, repeat, gitgutter, lightline)
- **tmux** — mouse support, `agent` alias for session management
- **Skills** — pre-installed opencode skills (add more in `Dockerfile`)

## Configuration

Set these in `.env`:

| Variable | Required | Purpose |
|---|---|---|
| `GITHUB_TOKEN` | ✅ | GitHub CLI auth, git over HTTPS |
| `GITHUB_USERNAME` | | Git commit name/email |
| `OPENCODE_API_KEY` | | opencode API key |

## Adding skills

Add a `RUN add-skill ...` line to the Dockerfile, then `make build`.

## Rebuilding

```bash
make build
```

Tears down the container, removes the home volume, and rebuilds from scratch.
