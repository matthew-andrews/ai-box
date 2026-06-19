#!/bin/bash
set -e

GITHUB_TOKEN=$(cat /run/secrets/github_token 2>/dev/null || echo "")
GITHUB_USERNAME=$(cat /run/secrets/github_username 2>/dev/null || echo "")
GITLAB_TOKEN=$(cat /run/secrets/gitlab_token 2>/dev/null || echo "")
GITLAB_USERNAME=$(cat /run/secrets/gitlab_username 2>/dev/null || echo "")
OPENCODE_ZEN_API_KEY=$(cat /run/secrets/opencode_zen_api_key 2>/dev/null || echo "")
OPENCODE_GO_API_KEY=$(cat /run/secrets/opencode_go_api_key 2>/dev/null || echo "")
OPENCODE_SERVER_PASSWORD=$(cat /run/secrets/opencode_server_password 2>/dev/null || echo "")
OPENCODE_SERVER_USERNAME=$(cat /run/secrets/opencode_server_username 2>/dev/null || echo "")

if [ -n "$GITHUB_TOKEN" ]; then
  mkdir -p /home/dev/.config/gh
  cat > /home/dev/.config/gh/hosts.yml << EOF
github.com:
    oauth_token: ${GITHUB_TOKEN}
    user: ${GITHUB_USERNAME}
    git_protocol: https
EOF
fi

if [ -n "$GITLAB_TOKEN" ]; then
  mkdir -p /home/dev/.config/glab-cli
  cat > /home/dev/.config/glab-cli/config.yml << EOF
hosts:
  gitlab.com:
    api_protocol: https
    token: ${GITLAB_TOKEN}
    user: ${GITLAB_USERNAME}
    git_protocol: https
EOF
  chmod 600 /home/dev/.config/glab-cli/config.yml
fi

if [ -n "$GITHUB_USERNAME" ]; then
  git config --global user.name "${GITHUB_USERNAME}"
  git config --global user.email "${GITHUB_USERNAME}@users.noreply.github.com"
elif [ -n "$GITLAB_USERNAME" ]; then
  git config --global user.name "${GITLAB_USERNAME}"
  git config --global user.email "${GITLAB_USERNAME}@users.noreply.github.com"
fi

if [ -n "$GITHUB_TOKEN" ]; then
  git config -f /home/dev/.gitconfig credential.https://github.com.helper "!gh auth git-credential"
fi
if [ -n "$GITLAB_TOKEN" ]; then
  git config -f /home/dev/.gitconfig credential.https://gitlab.com.helper "!glab auth git-credential"
fi

mkdir -p /home/dev/.config/opencode
if [ -f /home/dev/.config/opencode/opencode.json ]; then
  jq --arg model "${OPENCODE_MODEL:-opencode/deepseek-v4-flash-free}" \
    '."$schema" = "https://opencode.ai/config.json" | .model = $model' \
    /home/dev/.config/opencode/opencode.json > /tmp/opencode.json
  mv /tmp/opencode.json /home/dev/.config/opencode/opencode.json
else
  cat > /home/dev/.config/opencode/opencode.json << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "${OPENCODE_MODEL:-opencode/deepseek-v4-flash-free}"
}
EOF
fi

if [ -z "$OPENCODE_ZEN_API_KEY" ]; then
  echo "WARNING: OPENCODE_ZEN_API_KEY is not set. Zen models (including free DeepSeek V4 Flash Free) will not be available."
fi

mkdir -p /home/dev/.local/share/opencode
jq -n \
  --arg zen_key "$OPENCODE_ZEN_API_KEY" \
  --arg go_key "$OPENCODE_GO_API_KEY" \
  '{} 
  | if $zen_key != "" then .opencode = {"type": "api", "key": $zen_key} else . end
  | if $go_key != "" then .["opencode-go"] = {"type": "api", "key": $go_key} else . end' \
  > /home/dev/.local/share/opencode/auth.json

chown -R dev:dev /home/dev 2>/dev/null || true

if [ -n "$OPENCODE_SERVER_PASSWORD" ]; then
  export OPENCODE_SERVER_PASSWORD
  export OPENCODE_SERVER_USERNAME
  su dev -c 'opencode serve --hostname 0.0.0.0 --port 4096' \
    > /tmp/opencode-server.log 2>&1 &

  # Wait for the server to be ready, then start cloudflared tunnel
  (
    for i in $(seq 1 15); do
      if curl -s -o /dev/null http://localhost:4096 2>/dev/null; then
        break
      fi
      sleep 1
    done
    nohup cloudflared tunnel --url http://localhost:4096 \
      > /tmp/cloudflared.log 2>&1 &
    for i in $(seq 1 30); do
      TUNNEL_URL=$(grep -oP 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' /tmp/cloudflared.log 2>/dev/null | head -1)
      if [ -n "$TUNNEL_URL" ]; then
        echo "{\"url\": \"$TUNNEL_URL\"}" > /home/dev/.config/opencode/tunnel.json
        break
      fi
      sleep 1
    done
  ) &
fi

exec /usr/sbin/sshd -D
