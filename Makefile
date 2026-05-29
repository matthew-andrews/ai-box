build:
	@if [ "$$(uname -s)" != "Darwin" ] || [ "$$(uname -m)" != "arm64" ]; then \
		echo "Error: build is only supported on Apple Silicon (macOS arm64). Detected: $$(uname -s) $$(uname -m)" >&2; \
		exit 1; \
	fi
	mkdir -p secrets
	set -a; source .env 2>/dev/null; set +a; \
	  for var in GITHUB_TOKEN GITHUB_USERNAME GITLAB_TOKEN GITLAB_USERNAME OPENCODE_API_KEY; do \
	    printf '%s' "$${!var}" > "secrets/$$(echo "$$var" | tr '[:upper:]' '[:lower:]')"; \
	  done
	docker compose down -v
	docker compose up -d --build
