# Clears Docker build cache older than 24h so next build fetches latest versions
# (e.g. opencode-ai npm package, glab releases). ./workspace is preserved.
clear-cache:
	docker compose down -v
	docker builder prune -f --filter until=24h

build:
	@if [ "$$(uname -s)" != "Darwin" ] || [ "$$(uname -m)" != "arm64" ]; then \
		echo "Error: build is only supported on Apple Silicon (macOS arm64). Detected: $$(uname -s) $$(uname -m)" >&2; \
		exit 1; \
	fi
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found. Copy .env.example to .env and fill in your tokens." >&2; \
		exit 1; \
	fi
	mkdir -p secrets
	set -a; source .env; set +a; \
	  for var in GITHUB_TOKEN GITHUB_USERNAME GITLAB_TOKEN GITLAB_USERNAME OPENCODE_ZEN_API_KEY OPENCODE_GO_API_KEY OPENCODE_SERVER_PASSWORD OPENCODE_SERVER_USERNAME; do \
	    printf '%s' "$${!var}" > "secrets/$$(echo "$$var" | tr '[:upper:]' '[:lower:]')"; \
	  done
	docker compose down -v
	docker compose up -d --build
