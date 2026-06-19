#!/bin/bash
set -e

ENV_FILE=".env"

ensure_env() {
  if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
    echo "Created empty $ENV_FILE"
  fi
}

get_env() {
  local var_name="$1"
  if [ -f "$ENV_FILE" ]; then
    grep "^${var_name}=" "$ENV_FILE" | sed 's/^[^=]*=//'
  fi
}

update_env() {
  local var_name="$1"
  local var_value="$2"
  if grep -q "^${var_name}=" "$ENV_FILE" 2>/dev/null; then
    grep -v "^${var_name}=" "$ENV_FILE" > "${ENV_FILE}.tmp"
    printf '%s=%s\n' "${var_name}" "${var_value}" >> "${ENV_FILE}.tmp"
    mv "${ENV_FILE}.tmp" "$ENV_FILE"
  else
    printf '\n%s=%s\n' "${var_name}" "${var_value}" >> "$ENV_FILE"
  fi
}

prompt_secret() {
  local var_name="$1"
  local description="$2"
  local current
  current=$(get_env "$var_name")

  if [ -n "$current" ]; then
    local suffix="${current: -4}"
    read -r -s -p "${description} [ends in ...${suffix}, Enter to keep, or paste new]: " new_value
    echo
    if [ -n "$new_value" ]; then
      update_env "$var_name" "$new_value"
      echo "  ${var_name} updated"
    else
      echo "  ${var_name} kept"
    fi
  else
    read -r -s -p "${description} (paste token, or Enter to skip): " new_value
    echo
    if [ -n "$new_value" ]; then
      update_env "$var_name" "$new_value"
      echo "  ${var_name} saved"
    else
      echo "  ${var_name} skipped"
    fi
  fi
}

prompt_default() {
  local var_name="$1"
  local description="$2"
  local default="$3"
  local current
  current=$(get_env "$var_name")
  local display="${current:-$default}"

  read -r -p "${description} [${display}]: " new_value
  if [ -n "$new_value" ]; then
    update_env "$var_name" "$new_value"
    echo "  ${var_name} set to ${new_value}"
  elif [ -z "$current" ]; then
    update_env "$var_name" "$default"
    echo "  ${var_name} set to default (${default})"
  else
    echo "  ${var_name} kept (${current})"
  fi
}

auto_username() {
  local token_var="$1"
  local user_var="$2"
  local api_url="$3"
  local token
  token=$(get_env "$token_var")
  local existing_user
  existing_user=$(get_env "$user_var")

  if [ -z "$token" ] || [ -n "$existing_user" ]; then
    return
  fi

  local user
  user=$(curl -sSf --max-time 5 \
    -H "Authorization: token ${token}" \
    "${api_url}" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for key in ('login', 'username'):
        if key in data:
            print(data[key])
            break
except Exception:
    pass
" 2>/dev/null) || true

  if [ -n "$user" ]; then
    update_env "$user_var" "$user"
    echo "  ${user_var} auto-detected as ${user}"
  fi
}
