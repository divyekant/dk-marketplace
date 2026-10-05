// Self-check: node test.mjs
// Runs proxy.mjs against a fake cua_repl and checks meta injection, tool
// filtering, and the Stop-hook turn rotation.
import assert from "node:assert/strict";
import { spawn, execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";

const dir = fs.mkdtempSync(path.join(os.tmpdir(), "codex-cu-test-"));
const here = path.dirname(new URL(import.meta.url).pathname);

fs.writeFileSync(
  path.join(dir, "fake.mjs"),
  `import readline from "node:readline";
let lastEnded = null;
const out = (m) => process.stdout.write(JSON.stringify(m) + "\\n");
readline.createInterface({ input: process.stdin }).on("line", (l) => {
  const m = JSON.parse(l);
  if (m.method === "tools/list")
    out({ jsonrpc: "2.0", id: m.id, result: { tools: ["js", "js_reset", "js_add_node_module_dir", "turn_ended"].map((name) => ({ name })) } });
  if (m.method === "tools/call") {
    if (m.params.name === "turn_ended") lastEnded = m.params.arguments;
    out({ jsonrpc: "2.0", id: m.id, result: { meta: m.params._meta["x-codex-turn-metadata"], lastEnded } });
  }
});`,
);
fs.writeFileSync(
  path.join(dir, "mcp.json"),
  JSON.stringify({
    mcpServers: {
      cua_repl: { command: process.execPath, args: [path.join(dir, "fake.mjs")], enabled_tools: ["js", "js_reset", "turn_ended"] },
    },
  }),
);

const proxy = spawn(process.execPath, [path.join(here, "proxy.mjs")], {
  env: { ...process.env, CODEX_CU_MCP_JSON: path.join(dir, "mcp.json"), CLAUDE_CODE_SESSION_ID: "sess-1" },
  stdio: ["pipe", "pipe", "inherit"],
});
const waiting = new Map();
readline.createInterface({ input: proxy.stdout }).on("line", (l) => {
  const m = JSON.parse(l);
  waiting.get(m.id)?.(m);
});
let id = 0;
const rpc = (method, params) =>
  new Promise((resolve) => {
    waiting.set(++id, resolve);
    proxy.stdin.write(JSON.stringify({ jsonrpc: "2.0", id, method, params }) + "\n");
  });

const list = await rpc("tools/list", {});
assert.deepEqual(list.result.tools.map((t) => t.name), ["js", "js_reset"]);

const first = await rpc("tools/call", { name: "js", arguments: { code: "1" } });
const meta1 = JSON.parse(first.result.meta);
assert.equal(meta1.session_id, "sess-1");
assert.ok(meta1.turn_id);

execFileSync(process.execPath, [path.join(here, "proxy.mjs"), "--turn-ended"], { input: '{"hook_event_name":"Stop"}' });

const second = await rpc("tools/call", { name: "js", arguments: { code: "2" } });
const meta2 = JSON.parse(second.result.meta);
assert.deepEqual(second.result.lastEnded, { hook_event_name: "Stop", session_id: "sess-1", turn_id: meta1.turn_id });
assert.notEqual(meta2.turn_id, meta1.turn_id);

proxy.stdin.end();
fs.rmSync(dir, { recursive: true, force: true });
console.log("ok");
