# ai-box

An opinionated (only good opinions) Docker-based SSH development environment with AI coding tools pre-installed.

## Why

- **Sandbox your AI.** Running an AI coding agent inside a Docker container limits its filesystem access to what you explicitly mount — a lightweight safety boundary for your host machine.
- **Reproducible environment.** The entire dev environment (tools, configs, plugins, skills) is defined in code. One `make build` and you're on a fresh, identical setup anywhere.

## Quick start

```bash
cp .env.example .env
# edit .env with your keys
make build
ssh dev@localhost -p 2222
```

Once inside, run `agent` to start or attach to a tmux session.

## What's inside

- **SSH** — key-based auth only, password auth disabled, port 2222 → 22
- **Node.js 22** + **opencode-ai** — AI coding assistant
- **gh CLI** — authenticated via `GITHUB_TOKEN` from `.env`, git over HTTPS
- **vim** — 10 plugins (JS, JSON, Markdown, Dockerfile syntax; fugitive, commentary, surround, repeat, gitgutter, lightline); syntax highlighting, line numbers, 2-space tabs, folding disabled
- **tmux** — mouse support, 256-color terminal, `agent` alias for session management
- **Shell** — case-insensitive tab completion, history search via `.inputrc`
- **Skills** — pre-installed opencode skills (add more in `Dockerfile`)

## Configuration

Set these in `.env`:

| Variable | Purpose |
|---|---|
| `GITHUB_TOKEN` | GitHub CLI auth, git over HTTPS |
| `GITHUB_USERNAME` | Git commit name/email |
| `OPENCODE_API_KEY` | opencode API key |

## Adding skills

Add a `RUN add-skill ...` line to the Dockerfile, then `make build`.

## Rebuilding

```bash
make build
```

Tears down the container, removes the home volume, and rebuilds from scratch.
