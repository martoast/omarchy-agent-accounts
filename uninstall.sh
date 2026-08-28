#!/bin/bash
# Remove omarchy-agent-accounts.
#
# Leaves every account directory alone: sign-ins and history in ~/.claude,
# ~/.claude-profiles and ~/.codex-profiles are yours and are never touched.

set -euo pipefail

BIN="$HOME/.local/bin"

echo "Removing launchers from $BIN"
rm -f "$BIN"/{agent-profile,claude-profile,codex-profile,claude-real,codex-real}
rm -f "$BIN"/{claude-account,codex-account,agent-widget-patch}
rm -f "$BIN"/{omarchy-agent-usage-all,omarchy-agent-usage-profiles}
rm -rf "$BIN/agent-accounts" "$BIN/agent-usage-shims"
rm -f "$BIN"/claude[0-9] "$BIN"/codex[0-9]

echo "Removing the shell dispatcher from ~/.bashrc"
if grep -qF '# >>> omarchy-agent-accounts >>>' "$HOME/.bashrc" 2>/dev/null; then
  cp "$HOME/.bashrc" "$HOME/.bashrc.bak.$(date +%s)"
  sed -i '/# >>> omarchy-agent-accounts >>>/,/# <<< omarchy-agent-accounts <<</d' "$HOME/.bashrc"
fi

cat <<'DONE'

Removed. To finish putting the widget back the way it was:

  omarchy bar set <your-clone-id> providers '{"claude":{"enabled":true},"codex":{"enabled":true}}' --json
  omarchy plugin remove <your-clone-id>
  omarchy plugin enable omarchy.agents
  omarchy restart shell

Your accounts were left untouched: ~/.claude, ~/.claude-profiles, ~/.codex,
~/.codex-profiles. Remove those by hand if you actually want them gone.
DONE
