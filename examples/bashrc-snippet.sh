# Add to the end of ~/.bashrc. `install.sh` does this for you.
#
# The PATH entry alone is not enough: installers for these CLIs are fond of
# appending their own `export PATH="$HOME/.local/bin:$PATH"` to .bashrc, which
# puts their own launchers back in front of anything prepended earlier. A shell
# function always wins over PATH, so the dispatcher is guaranteed either way.

[[ -d "$HOME/.local/bin/agent-accounts" ]] && PATH="$HOME/.local/bin/agent-accounts:$PATH"

for _agent_cli in claude codex; do
  [[ -x "$HOME/.local/bin/agent-accounts/$_agent_cli" ]] || continue
  eval "$_agent_cli() { \"\$HOME/.local/bin/agent-accounts/$_agent_cli\" \"\$@\"; }"
done
unset _agent_cli
