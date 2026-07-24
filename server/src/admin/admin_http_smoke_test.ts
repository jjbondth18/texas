import Database from "better-sqlite3";
import { mkdirSync, rmSync } from "node:fs";
import { resolve } from "node:path";
import { spawn } from "node:child_process";
import { initializeSchema } from "../db/schema.js";

const root = resolve(process.cwd(), "data/admin-http-smoke");
const databasePath = resolve(root, "production.sqlite");
const backupDir = resolve(root, "backups");
const webRoot = resolve(process.cwd(), "../tools/admin/web");
rmSync(root, { recursive: true, force: true });
mkdirSync(root, { recursive: true });
const seed = new Database(databasePath);
initializeSchema(seed);
seed.close();

const port = 18787;
const child = spawn(process.execPath, ["dist/admin/index.js"], {
  cwd: process.cwd(),
  windowsHide: true,
  stdio: ["ignore", "pipe", "pipe"],
  env: {
    ...process.env,
    NODE_ENV: "production",
    ADMIN_HOST: "127.0.0.1",
    ADMIN_PORT: String(port),
    ADMIN_PIN: "phase2-smoke-pin",
    SQLITE_PATH: databasePath,
    ADMIN_BACKUP_DIR: backupDir,
    ADMIN_WEB_ROOT: webRoot,
  },
});
try {
  let health: Record<string, unknown> | undefined;
  for (let attempt=0; attempt<30; attempt++) {
    await new Promise((resolveWait)=>setTimeout(resolveWait,100));
    if (child.exitCode !== null) throw new Error(`Admin exited before health check: ${child.exitCode}`);
    try {
      const response = await fetch(`http://127.0.0.1:${port}/health`);
      health = await response.json() as Record<string, unknown>;
      break;
    } catch {}
  }
  if (health?.ok !== true || health.service !== "texas-admin" || health.databaseConnected !== true) throw new Error("minimal health response failed");
  if ("databasePath" in health || "pin" in health || "environment" in health) throw new Error("health response leaked sensitive information");
} finally {
  child.kill("SIGTERM");
  await new Promise((resolveWait)=>child.once("exit",resolveWait));
}

const rejected = spawn(process.execPath, ["dist/admin/index.js"], {
  cwd: process.cwd(),
  windowsHide: true,
  stdio: "ignore",
  env: {
    ...process.env,
    NODE_ENV: "production",
    ADMIN_HOST: "0.0.0.0",
    ADMIN_PORT: String(port+1),
    ADMIN_PIN: "phase2-smoke-pin",
    SQLITE_PATH: databasePath,
    ADMIN_BACKUP_DIR: backupDir,
    ADMIN_WEB_ROOT: webRoot,
  },
});
const rejectedCode = await new Promise<number|null>((resolveExit)=>rejected.once("exit",(code)=>resolveExit(code)));
if (rejectedCode === 0) throw new Error("Admin accepted a non-loopback bind");
rmSync(root, { recursive: true, force: true });
console.log("admin http smoke: ok");
