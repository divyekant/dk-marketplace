#!/usr/bin/env node
// Stdio MCP proxy for Codex's computer-use server (cua_repl).
//
// Proxy mode (default): starts cua_repl, adds _meta["x-codex-turn-metadata"]
// to every tools/call, and hides tools that Codex does not enable. It listens
// on /tmp/codex-cu-<uid>/<claude pid>.sock for turn-end requests.
//
// Hook mode (--turn-ended): finds the socket of the Claude process that ran the
// hook and tells that proxy to call turn_ended and start a new turn_id.

import { spawn, execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import fs from "node:fs";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";

const SOCK_DIR = `/tmp/codex-cu-${process.getuid()}`;
const META_KEY = "x-codex-turn-metadata";
const HIDDEN = new Set(["turn_ended"]);

if (process.argv.includes("--turn-ended")) await hook();
else proxy();

function resolveUpstream() {
  let file = process.env.CODEX_CU_MCP_JSON;
  if (!file) {
    const base = path.join(os.homedir(), ".codex/plugins/cache/openai-bundled/unified-computer-use");
    const newest = fs
      .readdirSync(base)
      .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }))
      .at(-1);
    if (!newest) throw new Error(`no unified-computer-use version in ${base}`);
    file = path.join(base, newest, ".mcp.json");
  }
  const entry = JSON.parse(fs.readFileSync(file, "utf8")).mcpServers?.cua_repl;
  if (!entry) throw new Error(`no cua_repl entry in ${file}`);
  return entry;
}

function proxy() {
  const upstream = resolveUpstream();
  const enabled = Array.isArray(upstream.enabled_tools) ? new Set(upstream.enabled_tools) : null;
  const sessionId = process.env.CLAUDE_CODE_SESSION_ID || randomUUID();
  let turnId = randomUUID();
  let calledThisTurn = false;

  const child = spawn(upstream.command, upstream.args ?? [], {
    env: { ...process.env, ...upstream.env },
    stdio: ["pipe", "pipe", "inherit"],
  });
  const toChild = (msg) => child.stdin.write(JSON.stringify(msg) + "\n");
  const toClient = (msg) => process.stdout.write(JSON.stringify(msg) + "\n");
  const turnMeta = () => JSON.stringify({ session_id: sessionId, turn_id: turnId });

  const listIds = new Set();
  const internal = new Map();
  let nextInternal = 0;

  readline.createInterface({ input: process.stdin }).on("line", (line) => {
    if (!line.trim()) return;
    const msg = JSON.parse(line);
    if (msg.method === "tools/list") listIds.add(msg.id);
    if (msg.method === "tools/call") {
      msg.params = { ...msg.params, _meta: { ...msg.params?._meta, [META_KEY]: turnMeta() } };
      calledThisTurn = true;
    }
    toChild(msg);
  });

  readline.createInterface({ input: child.stdout }).on("line", (line) => {
    if (!line.trim()) return;
    const msg = JSON.parse(line);
    if (internal.has(msg.id)) {
      internal.get(msg.id)(msg);
      internal.delete(msg.id);
      return;
    }
    if (listIds.delete(msg.id) && Array.isArray(msg.result?.tools)) {
      msg.result.tools = msg.result.tools.filter(
        (t) => !HIDDEN.has(t.name) && (!enabled || enabled.has(t.name)),
      );
    }
    toClient(msg);
  });

  async function endTurn(hookEventName) {
    if (!calledThisTurn) return;
    const id = `codex-cu:${nextInternal++}`;
    const done = new Promise((resolve) => {
      internal.set(id, resolve);
      setTimeout(resolve, 10_000).unref();
    });
    toChild({
      jsonrpc: "2.0",
      id,
      method: "tools/call",
      params: {
        name: "turn_ended",
        arguments: { hook_event_name: hookEventName, session_id: sessionId, turn_id: turnId },
        _meta: { [META_KEY]: turnMeta() },
      },
    });
    await done;
    turnId = randomUUID();
    calledThisTurn = false;
  }

  fs.mkdirSync(SOCK_DIR, { recursive: true, mode: 0o700 });
  const sockPath = path.join(SOCK_DIR, `${process.ppid}.sock`);
  fs.rmSync(sockPath, { force: true });
  const server = net.createServer((conn) => {
    let buf = "";
    conn.on("data", async (d) => {
      buf += d;
      if (!buf.includes("\n")) return;
      let event = "Stop";
      try {
        event = JSON.parse(buf).hook_event_name || event;
      } catch {}
      await endTurn(event);
      conn.end("ok\n");
    });
  });
  server.listen(sockPath);
  server.unref();

  const cleanup = () => fs.rmSync(sockPath, { force: true });
  process.on("exit", cleanup);
  process.stdin.on("end", () => child.kill());
  child.on("exit", (code) => process.exit(code ?? 0));
  for (const sig of ["SIGINT", "SIGTERM"]) process.on(sig, () => child.kill(sig));
}

async function hook() {
  let input = "";
  for await (const chunk of process.stdin) input += chunk;
  let event = "Stop";
  try {
    event = JSON.parse(input).hook_event_name || event;
  } catch {}

  // Walk up from the hook to the Claude process that owns the proxy.
  let pid = process.ppid;
  for (let hop = 0; hop < 10 && pid > 1; hop++) {
    const sock = path.join(SOCK_DIR, `${pid}.sock`);
    if (fs.existsSync(sock)) {
      await new Promise((resolve) => {
        const conn = net.connect(sock, () => conn.write(JSON.stringify({ hook_event_name: event }) + "\n"));
        conn.on("data", () => conn.end());
        conn.on("close", resolve);
        conn.on("error", resolve);
        setTimeout(resolve, 15_000).unref();
      });
      return;
    }
    try {
      pid = Number(execFileSync("ps", ["-o", "ppid=", "-p", String(pid)], { encoding: "utf8" }).trim());
    } catch {
      return;
    }
  }
}
