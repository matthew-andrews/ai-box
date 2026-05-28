# Contributing

## Adding a new tool

1. Install it in `Dockerfile` (use `apt-get` if available, otherwise document why not)
2. Configure it at startup in `entrypoint.sh` if it needs auth or setup
3. Add a "What's inside" bullet in `README.md`

## Adding a new environment variable

1. Add it to `.env.example` with an empty value
2. Pass it through in `docker-compose.yml` under `environment`
3. Use it in `entrypoint.sh` if needed at startup
4. Document it in the `README.md` configuration table

## Code style

- **Shell scripts**: `set -e`, no stray comments, keep it readable
- **Dockerfile**: `&&` chaining, one `RUN` per logical step, no unnecessary layers
- **Makefile**: single target, no over-engineering
- **Minimal comments**: let the code speak. Exception: explain *why* when the approach isn't obvious (e.g. "glab isn't in Debian apt repos")

## Docs reminder

Every functional change must update `README.md`. If someone has to read the code to understand your change, the docs aren't done.

## Building & testing

```bash
make build
ssh dev@localhost -p 2222
```

## Commit style

- One logical change per commit
- Imperative mood, no trailing period
- Match the existing style in `git log`
