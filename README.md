# ai-box

An opinionated (only good opinions) Docker-based SSH development environment with AI coding tools pre-installed.

## Why

- **Sandbox your AI.** Running an AI coding agent inside a Docker container limits its filesystem access to what you explicitly mount — a lightweight safety boundary for your host machine.
- **Reproducible environment.** The entire dev environment (tools, configs, plugins, skills) is defined in code. One `make build` and you're on a fresh, identical setup anywhere.
- **Portable terminal.** A consistent Linux environment you can SSH into from anywhere — iPad, another laptop, whatever. Everything is pre-configured and waiting.

## Quick start

```bash
cp ~/.ssh/id_ed25519.pub .ssh/id_ed25519.pub
cp .env.example .env
# edit .env with your keys (see Configuration below)
make build
ssh dev@localhost -p 2222
```

Once inside, run `agent` to start (or reconnect to) the `agent` tmux session, or `static` to serve the current directory on port 8080.

## What's inside

- **SSH** — key-based auth only, password auth disabled, port 2222 → 22. Drop your public key in `.ssh/id_ed25519.pub` (see `.ssh/id_ed25519.pub.example`).
- **static file server** — `static` alias runs `python3 -m http.server 8080` to serve the current directory; accessible at `http://localhost:8080` on the host.
- **Node.js 22** + **opencode-ai** — AI coding assistant
- **Gemini CLI** — `gemini` for an AI agent in your terminal, OAuth persists across rebuilds
- **gh CLI** + **glab CLI** — authenticated via `GITHUB_TOKEN` / `GITLAB_TOKEN` from `.env`, git over HTTPS
- **vim** — 10 plugins (JS, JSON, Markdown, Dockerfile syntax; fugitive, commentary, surround, repeat, gitgutter, lightline); syntax highlighting, line numbers, real tabs, folding disabled
- **tmux** — mouse support, 256-color terminal, `agent` alias for session management
- **Shell** — case-insensitive tab completion, history search via `.inputrc`
- **Skills** — pre-installed opencode skills (add more in `Dockerfile`)

## Configuration

Set these in `.env`. All variables are optional — configure only what you need.

| Variable | Purpose |
|---|---|
| `GITHUB_TOKEN` | GitHub CLI auth, git over HTTPS |
| `GITHUB_USERNAME` | Git commit name/email (GitHub) |
| `GITLAB_TOKEN` | GitLab CLI auth, git over HTTPS |
| `GITLAB_USERNAME` | GitLab username, fallback git commit identity |
| `OPENCODE_ZEN_API_KEY` | OpenCode Zen API key (pay-as-you-go models, `opencode/` prefix) |
| `OPENCODE_GO_API_KEY` | OpenCode Go API key (subscription models, `opencode-go/` prefix) |

### Git provider combinations

| Tokens set | What works |
|---|---|
| GitHub only | `gh` CLI authenticated, git commits use `GITHUB_USERNAME` |
| GitLab only | `glab` CLI authenticated, git commits use `GITLAB_USERNAME` |
| Both | Both CLIs authenticated, git commits use `GITHUB_USERNAME` |
| Neither | No git provider configured — manually run `git config` and auth if needed |

No combination will crash the container — missing tokens just skip the corresponding config.

## Gemini CLI authentication

Gemini CLI uses its own built-in OAuth — no API key or `.env` variable needed.

```bash
ssh dev@localhost -p 2222
gemini
```

The first time you run `gemini`, choose **Sign in with Google**. A URL will appear — open it in your host browser, authenticate, and paste the verification code back into the terminal.

Credentials are stored in `~/.gemini/`, which is bind-mounted to `./gemini-config/` on the host. This means authentication **survives `make build`** — you only authenticate once.

## Adding skills

Add a `RUN add-skill ...` line to the Dockerfile, then `make build`.

## Rebuilding

```bash
make build
```

Tears down the container, removes the home volume, and rebuilds from scratch.
