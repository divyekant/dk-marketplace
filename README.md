# codex-cu

A Claude Code plugin that gives Claude the computer-use runtime of the Codex app (`cua_repl`). With it, Claude can control Chrome through the Codex Chrome extension, the Codex in-app browser, and macOS apps.

## Requirements

- macOS with the Codex app (ChatGPT.app) installed.
- The Chrome plugin enabled in the Codex app, and the Codex Chrome extension installed.
- Node.js on `PATH`.

## Install

Install from [dk-marketplace](https://github.com/divyekant/dk-marketplace):

```bash
claude plugin marketplace add divyekant/dk-marketplace
```

```bash
claude plugin install codex-cu@dk-marketplace
```

Start a new Claude Code session. The tools show as `mcp__plugin_codex-cu_codex-cu__js` and `mcp__plugin_codex-cu_codex-cu__js_reset`.

To work on the plugin from a local clone, start Claude Code with `claude --plugin-dir <path to clone>`.

## How it works

| Part | File | Function |
|---|---|---|
| MCP server `codex-cu` | `.claude-plugin/plugin.json`, `proxy.mjs` | Starts `cua_repl` from the newest version in `~/.codex/plugins/cache/openai-bundled/unified-computer-use/`. Adds `_meta["x-codex-turn-metadata"]` to each `tools/call`. Shows only the tools that Codex enables, and hides `turn_ended`. |
| Stop hook | `hooks/hooks.json` | Runs `proxy.mjs --turn-ended`. The proxy of the same Claude session calls `turn_ended` and makes a new `turn_id`. Codex then releases the tabs of that turn. |

The browser side of `cua_repl` rejects a call that has no `session_id` and `turn_id` in the turn metadata. The proxy sends `CLAUDE_CODE_SESSION_ID` as `session_id`, and a new UUID as `turn_id` for each turn.

Each proxy listens on `/tmp/codex-cu-<uid>/<claude pid>.sock`. The hook goes up its process ancestors to the Claude process and uses only that socket. Other sessions do not get the message.

The proxy reads the Codex config each time it starts. Thus a Codex app update does not need a change to this plugin. To use a different config file, set `CODEX_CU_MCP_JSON` to its path.

## Limits

- The Stop hook does not run when you interrupt a turn. Tabs of an interrupted turn stay in use until the next turn ends.
- The proxy must be a direct child of the Claude process. Do not wrap the `node` command in `npx` or a shell.

## Test

```bash
node test.mjs
```

The test runs the proxy against a fake `cua_repl`. It checks the metadata, the tool filter, and the turn change from the Stop hook.
