# Contributing

## Adding a new tool

1. Install it in `Dockerfile` (use `apt-get` if available, otherwise document why not)
2. Configure it at startup in `entrypoint.sh` if it needs auth or setup
3. Add a "What's inside" bullet in `README.md`

## Adding a new environment variable

1. Pass it through in `docker-compose.yml` under `environment` or `secrets`
3. Use it in `entrypoint.sh` if needed at startup
4. Document it in the `README.md` configuration table

### User-supplied secrets (API keys, tokens)

If the new variable is a user-supplied secret:
- Add a `prompt_secret` call in the `build` target in `Makefile` for initial setup
- Create a dedicated `make auth-<name>` target in `Makefile` for rotation (see existing `auth-github`, `auth-gitlab`, `auth-opencode`)

### Auto-derivable values (usernames from tokens)

If the value can be derived from an existing secret (e.g. GitHub username from token):
- Add an `auto_*` function call in the `build` target after the secret's prompt
- Use `curl` + `python3` for API calls, silently skip on failure
- Add it to any relevant `make auth-*` target

All prompting and env-writing logic lives in `scripts/prompt-env.sh` — add helper functions there if needed.

## Code style

- **Shell scripts**: `set -e`, no stray comments, keep it readable
- **`scripts/` helpers**: reusable shell functions with clear names, sourced (not executed)
- **Dockerfile**: `&&` chaining, one `RUN` per logical step, no unnecessary layers
- **Makefile**: single target per concern (`build`, `auth-github`, `auth-opencode`, etc.), no over-engineering
- **Minimal comments**: let the code speak. Exception: explain *why* when the approach isn't obvious (e.g. "glab isn't in Debian apt repos")

## Docs reminder

Every functional change must update `README.md`. If someone has to read the code to understand your change, the docs aren't done.

## Building & testing

```bash
make build
```

`make build` will interactively prompt for any missing tokens. You can skip any prompt with Enter — you'll be prompted again next build. To update tokens without rebuilding, use `make auth-github`, `make auth-gitlab`, or `make auth-opencode`.

```bash
ssh dev@localhost -p 2222
```

## Commit style

- One logical change per commit
- Imperative mood, no trailing period
- Match the existing style in `git log`
