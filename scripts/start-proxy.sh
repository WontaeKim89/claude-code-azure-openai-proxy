#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ensure-env.sh"

cd "${ROOT_DIR}"

GENERATED_DIR="${ROOT_DIR}/.generated"
GENERATED_CONFIG="${GENERATED_DIR}/litellm.config.yaml"
mkdir -p "${GENERATED_DIR}"

sed \
  -e "s#__AZURE_DEPLOYMENT_NAME__#${AZURE_DEPLOYMENT_NAME}#g" \
  -e "s#__CLAUDE_CODE_MODEL_ALIAS__#${CLAUDE_CODE_MODEL_ALIAS}#g" \
  "${ROOT_DIR}/config/litellm.config.yaml" > "${GENERATED_CONFIG}"

printf 'Starting LiteLLM proxy on http://%s:%s\n' "${LITELLM_HOST}" "${LITELLM_PORT}"
printf 'Exposing model alias: %s -> azure/%s\n' "${CLAUDE_CODE_MODEL_ALIAS}" "${AZURE_DEPLOYMENT_NAME}"

exec uvx \
  --from 'litellm[proxy]!=1.82.7,!=1.82.8' \
  litellm \
  --config "${GENERATED_CONFIG}" \
  --host "${LITELLM_HOST}" \
  --port "${LITELLM_PORT}"
