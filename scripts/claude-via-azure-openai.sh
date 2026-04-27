#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ensure-env.sh"

export ANTHROPIC_BASE_URL="http://${LITELLM_HOST}:${LITELLM_PORT}"
export ANTHROPIC_AUTH_TOKEN="${LITELLM_MASTER_KEY}"
unset ANTHROPIC_API_KEY

export ANTHROPIC_MODEL="${CLAUDE_CODE_MODEL_ALIAS}"
export ANTHROPIC_DEFAULT_SONNET_MODEL="${CLAUDE_CODE_MODEL_ALIAS}"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="${CLAUDE_CODE_MODEL_ALIAS}"
export CLAUDE_CODE_SUBAGENT_MODEL="${CLAUDE_CODE_MODEL_ALIAS}"

export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="${CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC:-1}"
export DISABLE_TELEMETRY="${DISABLE_TELEMETRY:-1}"

if [[ "${CLAUDE_CODE_USE_CLEAN_CONFIG:-1}" == "1" ]]; then
  export CLAUDE_CONFIG_DIR="${ROOT_DIR}/.claude-runtime"
  mkdir -p "${CLAUDE_CONFIG_DIR}"
fi

printf 'Launching Claude Code via LiteLLM: %s, model=%s\n' "${ANTHROPIC_BASE_URL}" "${ANTHROPIC_MODEL}"
if [[ -n "${CLAUDE_CONFIG_DIR:-}" ]]; then
  printf 'Using isolated Claude config: %s\n' "${CLAUDE_CONFIG_DIR}"
fi
exec claude "$@"
