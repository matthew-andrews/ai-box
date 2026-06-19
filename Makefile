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
	@. scripts/prompt-env.sh && \
	  ensure_env && \
	  prompt_path "SSH_KEY_PATH" "SSH public key path" "~/.ssh/id_ed25519.pub" && \
	  prompt_secret "GITHUB_TOKEN" "GitHub personal access token" && \
	  auto_username "GITHUB_TOKEN" "GITHUB_USERNAME" "https://api.github.com/user" && \
	  prompt_secret "GITLAB_TOKEN" "GitLab personal access token" && \
	  auto_username "GITLAB_TOKEN" "GITLAB_USERNAME" "https://gitlab.com/api/v4/user" && \
	  prompt_secret "OPENCODE_ZEN_API_KEY" "OpenCode Zen API key" && \
	  prompt_secret "OPENCODE_GO_API_KEY" "OpenCode Go API key" && \
	  prompt_default "OPENCODE_MODEL" "Model" "opencode/deepseek-v4-flash-free"
	mkdir -p secrets
	set -a; source .env; set +a; \
	  for var in GITHUB_TOKEN GITHUB_USERNAME GITLAB_TOKEN GITLAB_USERNAME OPENCODE_ZEN_API_KEY OPENCODE_GO_API_KEY; do \
	    printf '%s' "$${!var}" > "secrets/$$(echo "$$var" | tr '[:upper:]' '[:lower:]')"; \
	  done
	docker compose down -v
	docker compose up -d --build

auth-github:
	@. scripts/prompt-env.sh && \
	  ensure_env && \
	  prompt_secret "GITHUB_TOKEN" "GitHub personal access token" && \
	  auto_username "GITHUB_TOKEN" "GITHUB_USERNAME" "https://api.github.com/user"

auth-gitlab:
	@. scripts/prompt-env.sh && \
	  ensure_env && \
	  prompt_secret "GITLAB_TOKEN" "GitLab personal access token" && \
	  auto_username "GITLAB_TOKEN" "GITLAB_USERNAME" "https://gitlab.com/api/v4/user"

auth-opencode:
	@. scripts/prompt-env.sh && \
	  ensure_env && \
	  prompt_secret "OPENCODE_ZEN_API_KEY" "OpenCode Zen API key" && \
	  prompt_secret "OPENCODE_GO_API_KEY" "OpenCode Go API key"
