#!/bin/bash
set -e

GITHUB_TOKEN=$(cat /run/secrets/github_token 2>/dev/null || echo "")
GITHUB_USERNAME=$(cat /run/secrets/github_username 2>/dev/null || echo "")
GITLAB_TOKEN=$(cat /run/secrets/gitlab_token 2>/dev/null || echo "")
GITLAB_USERNAME=$(cat /run/secrets/gitlab_username 2>/dev/null || echo "")
OPENCODE_API_KEY=$(cat /run/secrets/opencode_api_key 2>/dev/null || echo "")

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
  git config --global credential.helper "!gh auth git-credential"
fi
if [ -n "$GITLAB_TOKEN" ]; then
  git config --global credential.helper "!glab auth git-credential"
fi

mkdir -p /home/dev/.local/share/opencode
cat > /home/dev/.local/share/opencode/auth.json << EOF
{
  "opencode": {
    "type": "api",
    "key": "${OPENCODE_API_KEY}"
  }
}
EOF

sudo sh -c 'chown dev:dev /home/dev/.ssh /home/dev/.ssh/authorized_keys 2>/dev/null || true'

exec sudo /usr/sbin/sshd -D
