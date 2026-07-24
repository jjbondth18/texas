import { execFile } from "node:child_process";
import { existsSync, openSync, closeSync, readSync, statSync } from "node:fs";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const ALLOWED_NAMES = new Set(["texas-server", "texas-admin"]);

export async function serverStatus(): Promise<Record<string, unknown>> {
  const processes = await pm2Status();
  return {
    processes,
    game_error_log: tailFixedLog(process.env.GAME_ERROR_LOG),
    admin_error_log: tailFixedLog(process.env.ADMIN_ERROR_LOG),
  };
}

async function pm2Status(): Promise<unknown[]> {
  try {
    const { stdout } = await execFileAsync("pm2", ["jlist"], { timeout: 2500, maxBuffer: 1024 * 1024, windowsHide: true });
    const rows = JSON.parse(stdout) as Array<Record<string, any>>;
    return rows.filter((row) => ALLOWED_NAMES.has(String(row.name))).map((row) => ({
      name: row.name,
      online: row.pm2_env?.status === "online",
      status: row.pm2_env?.status ?? "unknown",
      uptime_seconds: row.pm2_env?.pm_uptime ? Math.max(0, Math.floor((Date.now() - Number(row.pm2_env.pm_uptime)) / 1000)) : null,
      restart_count: Number(row.pm2_env?.restart_time ?? 0),
      memory_bytes: Number(row.monit?.memory ?? 0),
    }));
  } catch {
    return [
      { name: "texas-server", status: "unavailable" },
      { name: "texas-admin", status: "unavailable" },
    ];
  }
}

function tailFixedLog(path: string | undefined): string {
  if (!path || !existsSync(path) || !statSync(path).isFile()) return "unavailable";
  const size = statSync(path).size;
  const bytes = Math.min(size, 32 * 1024);
  const buffer = Buffer.alloc(bytes);
  const fd = openSync(path, "r");
  try { readSync(fd, buffer, 0, bytes, size - bytes); } finally { closeSync(fd); }
  return buffer.toString("utf8").split(/\r?\n/).slice(-80).join("\n").slice(-16000);
}
