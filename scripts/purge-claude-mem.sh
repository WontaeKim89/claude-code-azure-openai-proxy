#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-${HOME}/.claude}"

printf 'Removing claude-mem from Claude Code global config...\n'

node <<'NODE'
const fs = require('fs');
const path = require('path');

const claudeDir = process.env.CLAUDE_DIR || path.join(process.env.HOME, '.claude');
const jsonFiles = [
  path.join(claudeDir, 'settings.json'),
  path.join(claudeDir, 'settings.local.json'),
  path.join(claudeDir, 'plugins', 'installed_plugins.json'),
  path.join(claudeDir, 'plugins', 'known_marketplaces.json'),
  path.join(claudeDir, 'plugins', 'config.json'),
  path.join(claudeDir, 'plugins', 'install-counts-cache.json')
];

function containsMemoryPlugin(value) {
  return /claude-mem|claude-memory|thedotmack|chroma-mcp/.test(JSON.stringify(value));
}

function scrub(value) {
  if (Array.isArray(value)) {
    return value.map(scrub).filter((item) => !containsMemoryPlugin(item));
  }
  if (value && typeof value === 'object') {
    for (const key of Object.keys(value)) {
      if (/claude-mem|claude-memory|thedotmack|chroma-mcp/.test(key)) {
        delete value[key];
        continue;
      }
      const next = scrub(value[key]);
      if (containsMemoryPlugin(next)) delete value[key];
      else value[key] = next;
    }
  }
  return value;
}

for (const file of jsonFiles) {
  if (!fs.existsSync(file)) continue;
  let parsed;
  try {
    parsed = JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    continue;
  }
  fs.writeFileSync(file, JSON.stringify(scrub(parsed), null, 2) + '\n');
  console.log(`scrubbed ${file}`);
}

const blocklistPath = path.join(claudeDir, 'plugins', 'blocklist.json');
let blocklist = { fetchedAt: new Date().toISOString(), plugins: [] };
if (fs.existsSync(blocklistPath)) {
  try {
    blocklist = JSON.parse(fs.readFileSync(blocklistPath, 'utf8'));
  } catch {}
}
if (!Array.isArray(blocklist.plugins)) blocklist.plugins = [];
for (const plugin of ['claude-mem@thedotmack', 'claude-memory@claude-plugins-official']) {
  if (!blocklist.plugins.some((entry) => entry.plugin === plugin)) {
    blocklist.plugins.push({
      plugin,
      added_at: new Date().toISOString(),
      reason: 'disabled-locally',
      text: 'Disabled locally to prevent token-heavy memory context and stale hook failures.'
    });
  }
}
fs.mkdirSync(path.dirname(blocklistPath), { recursive: true });
fs.writeFileSync(blocklistPath, JSON.stringify(blocklist, null, 2) + '\n');
console.log(`updated ${blocklistPath}`);
NODE

printf 'Stopping existing claude-mem/chroma processes...\n'
PIDS="$(ps ax -o pid=,command= | awk '/claude-mem|chroma-mcp|thedotmack/ && !/awk/ {print $1}' | sort -u || true)"
if [[ -n "${PIDS}" ]]; then
  kill ${PIDS} 2>/dev/null || true
  sleep 1
  PIDS="$(ps ax -o pid=,command= | awk '/claude-mem|chroma-mcp|thedotmack/ && !/awk/ {print $1}' | sort -u || true)"
  if [[ -n "${PIDS}" ]]; then
    kill -9 ${PIDS} 2>/dev/null || true
  fi
fi

printf 'Deleting claude-mem plugin/data directories...\n'
rm -rf \
  "${CLAUDE_DIR}/plugins/cache/thedotmack" \
  "${CLAUDE_DIR}/plugins/marketplaces/thedotmack" \
  "${CLAUDE_DIR}/plugins/marketplaces/thedotmack-claude-mem" \
  "${CLAUDE_DIR}/plugins/data/claude-mem-thedotmack" \
  "${CLAUDE_DIR}/projects/-Users-gim-wontae--claude-mem-observer-sessions" \
  "${HOME}/.claude-mem"

printf 'Verifying removal...\n'
if ps ax -o command= | grep -E 'claude-mem|chroma-mcp|thedotmack' | grep -v grep >/dev/null; then
  printf 'Warning: some claude-mem related processes still exist. Close old Claude Code terminals and rerun this script.\n' >&2
  exit 1
fi

if find "${CLAUDE_DIR}/plugins" -maxdepth 5 \( -iname '*claude-mem*' -o -iname '*thedotmack*' \) -print 2>/dev/null | grep -q .; then
  printf 'Warning: some claude-mem plugin files still exist.\n' >&2
  exit 1
fi

printf 'claude-mem purge complete.\n'

