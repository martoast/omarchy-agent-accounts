#!/bin/bash
# Install omarchy-agent-accounts.
#
# Copies the launchers into ~/.local/bin, wires the shell dispatcher into
# ~/.bashrc, and clones + patches the Omarchy agents widget so each account
# gets its own tab. Re-running it is safe; nothing here is destructive.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
MARKER="# >>> omarchy-agent-accounts >>>"

say() { printf '%s\n' "$*"; }

say "Installing launchers into $BIN"
mkdir -p "$BIN/agent-accounts" "$BIN/agent-usage-shims"
for f in "$SRC"/bin/*; do
  [[ -f $f ]] || continue
  install -m 755 "$f" "$BIN/$(basename "$f")"
done
install -m 755 "$SRC"/bin/agent-accounts/* "$BIN/agent-accounts/"
install -m 755 "$SRC"/bin/agent-usage-shims/* "$BIN/agent-usage-shims/"

if grep -qF "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
  say "Shell dispatcher already present in ~/.bashrc"
else
  say "Adding the shell dispatcher to ~/.bashrc"
  {
    printf '\n%s\n' "$MARKER"
    cat "$SRC/examples/bashrc-snippet.sh"
    printf '%s\n' "# <<< omarchy-agent-accounts <<<"
  } >>"$HOME/.bashrc"
fi

# The packaged widget lives under /usr/share/omarchy, which is read-only and
# replaced on update, so the per-account tabs run from a clone.
if command -v omarchy >/dev/null 2>&1; then
  if ! ls "$HOME"/.config/omarchy/plugins/*/manifest.json >/dev/null 2>&1 ||
    ! grep -ql '"clonedFrom": *"omarchy.agents"' "$HOME"/.config/omarchy/plugins/*/manifest.json 2>/dev/null; then
    say "Cloning the Omarchy agents widget"
    omarchy plugin clone omarchy.agents
  fi
  say "Patching the widget clone"
  clone=$(grep -l '"clonedFrom": *"omarchy.agents"' "$HOME"/.config/omarchy/plugins/*/manifest.json | head -1)
  "$BIN/agent-widget-patch" "$(dirname "$clone")"

  widget_id=$(jq -r .id "$clone")
  say "Switching off the stock claude/codex providers on $widget_id"
  omarchy bar set "$widget_id" providers \
    '{"claude":{"enabled":false},"codex":{"enabled":false}}' --json
  rm -f "${XDG_STATE_HOME:-$HOME/.local/state}"/omarchy/agents/usage/{claude,codex}.json

  for cli in claude codex; do
    command -v "$cli" >/dev/null 2>&1 || continue
    AGENT_KIND="$cli" "$BIN/agent-profile" link 1 >/dev/null 2>&1 || true
  done
  omarchy restart shell >/dev/null 2>&1 || true
else
  say "omarchy not found — skipping the widget half; the CLIs still work"
fi

cat <<'DONE'

Installed. Open a new terminal, then:

  claude-profile list          what you have now
  claude-profile add 2         add a second Claude account and sign it in
  codex-profile add 2          same for Codex

See examples/bindings.lua for keybindings that show up under SUPER + K.
DONE
