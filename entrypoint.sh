#!/bin/bash
set -e

mkdir -p /home/dev/.config/gh

cat > /home/dev/.config/gh/hosts.yml << EOF
github.com:
    oauth_token: ${GITHUB_TOKEN}
    user: ${GITHUB_USERNAME}
    git_protocol: https
EOF

git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${GITHUB_USERNAME}@users.noreply.github.com"

mkdir -p /home/dev/.local/share/opencode
cat > /home/dev/.local/share/opencode/auth.json << EOF
{
  "opencode": {
    "type": "api",
    "key": "${OPENCODE_API_KEY}"
  }
}
EOF

exec sudo /usr/sbin/sshd -D
