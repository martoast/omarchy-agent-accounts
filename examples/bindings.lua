-- Add to ~/.config/hypr/bindings.lua.
--
-- A keybinding starts its command with no shell, so the dispatcher function
-- that ~/.bashrc defines never loads. That is why these call the launcher
-- scripts (claude-account, claude1, ...) rather than a bare `claude`.
--
-- Descriptions matter: SUPER + K lists every binding with its description,
-- which makes that menu the reminder of which account is which. Do not use a
-- comma in a description — the keybindings menu truncates it there.

o.bind("SUPER + CTRL + SHIFT + RETURN", "Claude Code (default account)", "omarchy-launch-terminal claude-account")
o.bind("SUPER + CTRL + ALT + RETURN", "Codex (default account)", "omarchy-launch-terminal codex-account")

o.bind("SUPER + CTRL + 1", "Claude Code - account 1 (claude1)", "omarchy-launch-terminal claude1")
o.bind("SUPER + CTRL + 2", "Claude Code - account 2 (claude2)", "omarchy-launch-terminal claude2")
o.bind("SUPER + ALT + 1", "Codex - account 1 (codex1)", "omarchy-launch-terminal codex1")

o.bind("SUPER + CTRL + A", "AI accounts", "omarchy-launch-terminal bash -lic 'claude-profile list; echo; codex-profile list; echo; exec bash'")
