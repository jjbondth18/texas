import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawn, type ChildProcess } from "node:child_process";

const root = mkdtempSync(join(tmpdir(), "texas-virtual-admin-api-"));
const databasePath = join(root, "test.sqlite");
const port = 19808;
const child = startServer(port, databasePath, true);
try {
  await waitForHealth(port, child);
  const initial = await jsonRequest(port, "/admin/virtual");
  assert.equal(initial.status, 200);
  const state = initial.body as any;
  assert.equal(typeof state.health, "object");
  assert.equal(typeof state.config, "object");
  assert.equal(Array.isArray(state.profiles), true);
  assert.equal(Array.isArray(state.recent_events), true);
  assert.equal(Array.isArray(state.filled_rooms), true);
  assert.equal("session_hand_target" in state.profiles[0], true);

  assert.equal((await jsonRequest(port, "/admin/virtual/enabled?value=true", "POST")).status, 200);
  assert.equal((await jsonRequest(port, "/admin/virtual/enabled?value=false", "POST")).status, 200);
  assert.equal((await jsonRequest(port, "/admin/virtual/config?target_online=2&maximum_online=4&maximum_per_room=1&join_delay_min_ms=1000&join_delay_max_ms=2000&session_hand_min=3&session_hand_max=8", "POST")).status, 200);
  assert.equal((await jsonRequest(port, "/admin/virtual/config?target_online=5&maximum_online=4", "POST")).status, 400);
  assert.equal((await jsonRequest(port, "/admin/virtual/config?join_delay_min_ms=2000&join_delay_max_ms=1000", "POST")).status, 400);
  assert.equal((await jsonRequest(port, "/admin/virtual/profile?player_id=virtual%3Avp_001&enabled=false", "POST")).status, 200);
  assert.equal((await jsonRequest(port, "/admin/virtual/profile?player_id=virtual%3Avp_001&enabled=true", "POST")).status, 200);
  assert.equal((await jsonRequest(port, "/admin/virtual/offline?player_id=virtual%3Avp_001", "POST")).status, 200);
  assert.equal((await jsonRequest(port, "/admin/virtual/offline", "POST")).status, 200);
} finally {
  await stopServer(child);
}

const rejectedPort = port + 1;
const rejected = startServer(rejectedPort, join(root, "disabled.sqlite"), false);
try {
  await waitForHealth(rejectedPort, rejected);
  const response = await fetch(`http://127.0.0.1:${rejectedPort}/admin/virtual`);
  assert.equal(response.status, 403, "disabled admin access must reject Virtual management state");
} finally {
  await stopServer(rejected);
  rmSync(root, { recursive: true, force: true });
}
console.log("virtual admin API test: ok");

function startServer(serverPort: number, sqlitePath: string, adminEnabled: boolean): ChildProcess {
  return spawn(process.execPath, ["dist/index.js"], {
    cwd: process.cwd(),
    windowsHide: true,
    stdio: ["ignore", "pipe", "pipe"],
    env: {
      ...process.env,
      NODE_ENV: "test",
      HOST: "127.0.0.1",
      PORT: String(serverPort),
      TEXAS_DB_PATH: sqlitePath,
      ADMIN_ENABLED: String(adminEnabled),
      ADMIN_LOCAL_ONLY: "true",
      VIRTUAL_PLAYERS_ENABLED: "false",
    },
  });
}

async function waitForHealth(serverPort: number, childProcess: ChildProcess): Promise<void> {
  for (let attempt = 0; attempt < 50; attempt += 1) {
    if (childProcess.exitCode !== null) throw new Error(`server exited early: ${childProcess.exitCode}`);
    try {
      const response = await fetch(`http://127.0.0.1:${serverPort}/healthz`);
      if (response.ok) return;
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error("server health timeout");
}

async function jsonRequest(serverPort: number, path: string, method = "GET"): Promise<{ status: number; body: unknown }> {
  const response = await fetch(`http://127.0.0.1:${serverPort}${path}`, { method });
  return { status: response.status, body: await response.json() };
}

async function stopServer(childProcess: ChildProcess): Promise<void> {
  if (childProcess.exitCode !== null) return;
  childProcess.kill("SIGTERM");
  await new Promise((resolve) => childProcess.once("exit", resolve));
}
