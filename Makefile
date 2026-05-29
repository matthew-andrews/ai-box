build:
	mkdir -p secrets
	set -a; source .env 2>/dev/null; set +a; \
	  for var in GITHUB_TOKEN GITHUB_USERNAME GITLAB_TOKEN GITLAB_USERNAME OPENCODE_API_KEY; do \
	    printf '%s' "$${!var}" > "secrets/$$(echo "$$var" | tr '[:upper:]' '[:lower:]')"; \
	  done
	docker compose down -v
	docker compose up -d --build
