#!/bin/bash
set -e

GITHUB_TOKEN=$(cat /run/secrets/github_token 2>/dev/null || echo "")
GITHUB_USERNAME=$(cat /run/secrets/github_username 2>/dev/null || echo "")
GITLAB_TOKEN=$(cat /run/secrets/gitlab_token 2>/dev/null || echo "")
GITLAB_USERNAME=$(cat /run/secrets/gitlab_username 2>/dev/null || echo "")
OPENCODE_ZEN_API_KEY=$(cat /run/secrets/opencode_zen_api_key 2>/dev/null || echo "")
OPENCODE_GO_API_KEY=$(cat /run/secrets/opencode_go_api_key 2>/dev/null || echo "")
OPENCODE_SERVER_PASSWORD=$(cat /run/secrets/opencode_server_password 2>/dev/null || echo "")

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
cat > /home/dev/.config/opencode/opencode.json << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "${OPENCODE_MODEL:-opencode-go/deepseek-v4-flash}"
}
EOF

mkdir -p /home/dev/.local/share/opencode
cat > /home/dev/.local/share/opencode/auth.json << EOF
{
  "opencode": {
    "type": "api",
    "key": "${OPENCODE_ZEN_API_KEY}"
  },
  "opencode-go": {
    "type": "api",
    "key": "${OPENCODE_GO_API_KEY}"
  }
}
EOF

chown -R dev:dev /home/dev 2>/dev/null || true

if [ -n "$OPENCODE_SERVER_PASSWORD" ]; then
  export OPENCODE_SERVER_PASSWORD
  su dev -c 'opencode serve --hostname 0.0.0.0 --port 4096' \
    > /tmp/opencode-server.log 2>&1 &
fi

exec /usr/sbin/sshd -D
