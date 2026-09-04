# omarchy-agent-accounts

Run several Claude Code and Codex subscriptions on one machine, and see all of
them at once in the [Omarchy](https://omarchy.org) agents bar widget.

Neither CLI has an account switcher, and Omarchy's agents widget assumes one
account per agent. If you have two Claude Max plans you can only use one at a
time, and the widget only ever shows that one's limits.

```
[ Claude 1 ]  [ Claude 2 ● ]  [ Codex 1 ]
[      Make default for claude   d      ]

LIMITS
Session (5-hour)                     34%
Weekly (7-day)                       17%
```

- **One tab per account**, each with its own live rate limits.
- `claude1`, `claude2`, `codex1` … run a specific account, and so does
  `claude --account 2` (or `--account=2`). They are ordinary processes, so
  **two accounts can run side by side**, one terminal each.
- A bare `claude` or `codex` runs whichever account is marked default.
- The default is set from the widget — a dot marks it, and a button under the
  tabs moves it. Browsing another account's usage does not change it.

## How it works

Each account is one config directory, selected by the agent's own home
variable — `CLAUDE_CONFIG_DIR` for Claude Code, `CODEX_HOME` for Codex. That
gives each account a separate sign-in, history, and usage.

```
~/.claude               account1   (untouched; runs with no home variable set)
~/.claude-profiles/
  account2/             account2
~/.codex                account1
~/.codex-profiles/
  account2/             account2
```

`account1` deliberately keeps the CLI's original directory and runs with the
home variable *unset*. Claude Code keeps `.claude.json` beside `~/.claude`
rather than inside it, and pointing `CLAUDE_CONFIG_DIR` at `~/.claude` would
strand that file. Nothing has to move to install this.

Config that is not account-specific is symlinked from `account1` into the
others — `settings.json`, `skills`, `plugins`, and each
`projects/<slug>/memory` for Claude; `config.toml`, `skills`, `AGENTS.md` for
Codex. `projects/` itself stays separate, because that is what the usage
numbers are derived from.

### The widget

Omarchy's agents panel draws whatever JSON records it finds in
`~/.local/state/omarchy/agents/usage/`, whoever wrote them, and resolves each
tab's icon as `assets/<record-id>.svg`. So a second subscription needs only a
second record.

`omarchy-agent-usage-profiles` runs Omarchy's own collector once per account,
pinned to that account, and relabels the output as `claude-account2`,
`codex-account1`, and so on. The stock single-account `claude`/`codex`
providers are switched off so they do not claim a duplicate tab.

`/usr/share/omarchy` is read-only and replaced on update, so the widget runs
from a clone that differs from upstream by only:

- the manifest id,
- `assets/<agent>-account<n>.svg` symlinks to the stock marks,
- two patched files (`agent-widget-patch` re-applies both, idempotently):
  - `Panel.qml` — the default-account store, the dot, the toggle, the `d` key,
  - `Main.qml` — one line, calling `omarchy-agent-usage-all` instead of
    `omarchy-agent-usage-update`, so accounts refresh on the panel's own timer
    and refresh key rather than needing a second scheduler.

Run `claude-profile widget-sync` after `omarchy update` to pull upstream
changes back into the clone and re-apply those patches.

## Install

```bash
git clone https://github.com/<you>/omarchy-agent-accounts
cd omarchy-agent-accounts
./install.sh
```

Then open a new terminal and add an account:

```bash
claude-profile add 2     # creates ~/.claude-profiles/account2 and signs it in
codex-profile add 2
```

Keybindings are opt-in; copy what you want from
[`examples/bindings.lua`](examples/bindings.lua) into
`~/.config/hypr/bindings.lua`. Their descriptions show up under `SUPER + K`,
which makes that menu the reminder of which key opens which account.

## Commands

```
claude1, claude2, codex1 …      run a specific account
claude --account 2, codex --account 1   same thing as a flag (also --account=2)
claude, codex                   run the default account

<cli>-profile list              accounts, emails, plans, which is default
<cli>-profile use <n>           set the default from the shell
<cli>-profile add <n>           create an account and sign it in
<cli>-profile login <n>         sign an account in (or back in)
<cli>-profile link <n>          repair shared config and launchers
<cli>-profile doctor            check the whole setup
<cli>-profile widget-sync       re-sync the widget clone from upstream
<cli>-profile remove <n>        delete an account
```

`<cli>` is `claude` or `codex`; both are thin wrappers around `agent-profile`.

## Notes

**The dispatcher is a shell function.** Installers for these CLIs like to
append their own `export PATH="$HOME/.local/bin:$PATH"` to `.bashrc`, which
puts their launchers back in front of anything prepended earlier. A function
beats PATH unconditionally. `claude-real` / `codex-real` bypass it, and a
keybinding — which runs with no shell — should call `claude-account` or
`claude1` rather than a bare `claude`.

**Nested calls stay put.** `claude-profile run` exports `CLAUDE_ACCOUNT` /
`CODEX_ACCOUNT`; the dispatcher honours it, so an agent that shells out to
itself stays on the account that started it rather than jumping to whatever
the widget is showing.

**Token charts are local; limit meters are not.** "Tokens by day" and "Tokens
by model" are scanned from transcripts on this machine and include cache-read
tokens, which dominate the totals. The limit meters come from the provider and
cover the account everywhere. An account used mostly on the web shows real
limits next to an empty chart, and that is not a bug.

**A Codex fix rides along.** Omarchy's Codex collector starts the app-server
with `-a untrusted`, an approval policy codex-cli dropped — 0.150.0 accepts
only `on-request` or `never` — so the panel reports "Codex limits
unavailable". `bin/agent-usage-shims/codex` rewrites that one flag and is put
on PATH only for collector runs, never for an interactive `codex`. Remove it
once Omarchy fixes the flag upstream.

## Requirements

Omarchy (for the widget half), `jq`, and whichever CLIs you use. The account
management works without Omarchy; only the bar widget needs it.

## License

MIT
