import assert from "node:assert/strict";
import Database from "better-sqlite3";
import { createServer } from "node:http";
import { mkdirSync, rmSync } from "node:fs";
import { resolve } from "node:path";
import { spawn } from "node:child_process";
import { initializeSchema } from "../db/schema.js";

const root = resolve(process.cwd(), "data/admin-virtual-http");
const databasePath = resolve(root, "production.sqlite");
const backupDir = resolve(root, "backups");
const webRoot = resolve(process.cwd(), "../tools/admin/web");
const gamePort = 18081;
const adminPort = 18789;
rmSync(root, { recursive: true, force: true });
mkdirSync(root, { recursive: true });
const seed = new Database(databasePath);
initializeSchema(seed);
seed.close();

const upstreamCalls: Array<{ method: string; path: string }> = [];
const gameServer = createServer((request, response) => {
  const url = new URL(request.url || "/", `http://127.0.0.1:${gamePort}`);
  upstreamCalls.push({ method: request.method || "", path: `${url.pathname}${url.search}` });
  response.writeHead(200, { "content-type": "application/json" });
  if (url.pathname === "/admin/virtual") {
    response.end(JSON.stringify({
      health: { enabled: true, online: 1 },
      config: { target_online: 1, maximum_online: 2, maximum_per_room: 1 },
      profiles: [{ virtual_player_id: "virtual:vp_001", session_hands_played: 1, session_hand_target: 3 }],
      recent_events: [],
      filled_rooms: [],
    }));
  } else {
    response.end(JSON.stringify({ ok: true }));
  }
});
await new Promise<void>((resolveListen) => gameServer.listen(gamePort, "127.0.0.1", resolveListen));

const child = spawn(process.execPath, ["dist/admin/index.js"], {
  cwd: process.cwd(),
  windowsHide: true,
  stdio: ["ignore", "pipe", "pipe"],
  env: {
    ...process.env,
    NODE_ENV: "production",
    ADMIN_HOST: "127.0.0.1",
    ADMIN_PORT: String(adminPort),
    ADMIN_PIN: "virtual-http-smoke",
    SQLITE_PATH: databasePath,
    ADMIN_BACKUP_DIR: backupDir,
    ADMIN_WEB_ROOT: webRoot,
    GAME_SERVER_ADMIN_URL: `http://127.0.0.1:${gamePort}`,
  },
});
try {
  await waitForAdmin();
  const unauthorized = await fetch(`http://127.0.0.1:${adminPort}/api/virtual`);
  assert.equal(unauthorized.status, 401);

  const login = await fetch(`http://127.0.0.1:${adminPort}/api/session`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ pin: "virtual-http-smoke" }),
  });
  assert.equal(login.status, 200);
  const cookie = login.headers.get("set-cookie")?.split(";")[0] || "";
  assert.match(cookie, /^admin_session=/);

  const state = await adminRequest("/api/virtual", "GET", undefined, cookie);
  assert.equal(state.status, 200);
  assert.equal((state.body as any).profiles[0].session_hand_target, 3);
  await adminRequest("/api/virtual/enabled", "POST", { enabled: false }, cookie);
  await adminRequest("/api/virtual/config", "POST", {
    target_online: 1,
    maximum_online: 2,
    maximum_per_room: 1,
    join_delay_min_ms: 1000,
    join_delay_max_ms: 2000,
    session_hand_min: 3,
    session_hand_max: 8,
  }, cookie);
  await adminRequest("/api/virtual/profile", "POST", { player_id: "virtual:vp_001", enabled: false }, cookie);
  await adminRequest("/api/virtual/offline", "POST", { player_id: "virtual:vp_001" }, cookie);
  await adminRequest("/api/virtual/offline", "POST", {}, cookie);
  assert.deepEqual(upstreamCalls.map((call) => [call.method, new URL(call.path, "http://local").pathname]), [
    ["GET", "/admin/virtual"],
    ["POST", "/admin/virtual/enabled"],
    ["POST", "/admin/virtual/config"],
    ["POST", "/admin/virtual/profile"],
    ["POST", "/admin/virtual/offline"],
    ["POST", "/admin/virtual/offline"],
  ]);

  const invalid = await adminRequest("/api/virtual/config", "POST", {
    target_online: 3,
    maximum_online: 2,
    maximum_per_room: 1,
    join_delay_min_ms: 1000,
    join_delay_max_ms: 2000,
    session_hand_min: 3,
    session_hand_max: 8,
  }, cookie);
  assert.equal(invalid.status, 400);
  assert.match(String((invalid.body as any).error), /target_online/);
  assert.equal(upstreamCalls.length, 6, "invalid config must be rejected before reaching the game server");

  const arbitrary = await adminRequest("/api/virtual/proxy", "POST", { url: "http://example.com" }, cookie);
  assert.equal(arbitrary.status, 404);
  assert.equal(upstreamCalls.length, 6, "arbitrary proxy route must never reach the game server");

  await new Promise<void>((resolveClose) => gameServer.close(() => resolveClose()));
  const unavailable = await adminRequest("/api/virtual", "GET", undefined, cookie);
  assert.equal(unavailable.status, 502);
  assert.match(String((unavailable.body as any).error), /游戏服务不可达/);
} finally {
  if (gameServer.listening) await new Promise<void>((resolveClose) => gameServer.close(() => resolveClose()));
  child.kill("SIGTERM");
  await new Promise((resolveExit) => child.once("exit", resolveExit));
  rmSync(root, { recursive: true, force: true });
}
console.log("admin virtual HTTP integration: ok");

async function waitForAdmin(): Promise<void> {
  for (let attempt = 0; attempt < 50; attempt += 1) {
    if (child.exitCode !== null) throw new Error(`Admin exited early: ${child.exitCode}`);
    try {
      const response = await fetch(`http://127.0.0.1:${adminPort}/health`);
      if (response.ok) return;
    } catch {}
    await new Promise((resolveWait) => setTimeout(resolveWait, 100));
  }
  throw new Error("Admin health timeout");
}

async function adminRequest(path: string, method: string, body: unknown, cookie: string): Promise<{ status: number; body: unknown }> {
  const response = await fetch(`http://127.0.0.1:${adminPort}${path}`, {
    method,
    headers: { cookie, "content-type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return { status: response.status, body: await response.json() };
}
