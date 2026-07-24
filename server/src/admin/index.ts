import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { createReadStream, existsSync } from "node:fs";
import { extname, resolve } from "node:path";
import { randomBytes } from "node:crypto";
import { AdminRepository } from "./admin_repository.js";
import { openAdminDatabase, validateBackupDirectory } from "./admin_startup.js";
import { serverStatus } from "./server_status.js";

const host = process.env.ADMIN_HOST || "127.0.0.1";
if (host !== "127.0.0.1") throw new Error("ADMIN_HOST must be exactly 127.0.0.1");
const port = positiveInt(process.env.ADMIN_PORT, 8787);
const pin = process.env.ADMIN_PIN || "";
if (pin.length < 6) throw new Error("ADMIN_PIN must contain at least 6 characters");
const staticRoot = resolve(process.cwd(), process.env.ADMIN_WEB_ROOT || "../tools/admin/web");
const backupRoot = validateBackupDirectory(process.env.ADMIN_BACKUP_DIR || "");
const healthUrl = process.env.GAME_SERVER_HEALTH_URL || "http://127.0.0.1:8080/healthz";
const started = await openAdminDatabase({
  sqlitePath: process.env.SQLITE_PATH || "",
  backupDir: backupRoot,
  nodeEnv: process.env.NODE_ENV || "production",
});
const db = started.db;
const repository = new AdminRepository(db);
const sessions = new Set<string>();

const server = createServer(async (req, res) => {
  try {
    securityHeaders(res);
    const url = new URL(req.url || "/", `http://${host}:${port}`);
    if (req.method === "GET" && url.pathname === "/health") {
      const connected = Boolean(db.prepare("SELECT 1 value").get());
      return json(res, connected ? 200 : 503, { ok: connected, service: "texas-admin", databaseConnected: connected });
    }
    if (req.method === "POST" && url.pathname === "/api/session") {
      const body = await jsonBody(req);
      if (body.pin !== pin) return json(res, 401, { error: "PIN 错误" });
      const token = randomBytes(32).toString("hex");
      sessions.add(token);
      res.setHeader("Set-Cookie", `admin_session=${token}; HttpOnly; SameSite=Strict; Path=/`);
      return json(res, 200, { ok: true });
    }
    if (url.pathname.startsWith("/api/")) {
      if (!authorized(req)) return json(res, 401, { error: "请先输入本地 Admin PIN" });
      if (req.method === "GET" && url.pathname === "/api/dashboard") {
        return json(res, 200, { ...repository.dashboard(), game_server: await gameStatus() });
      }
      const page = positiveInt(url.searchParams.get("page") || undefined, 1);
      if (req.method === "GET" && url.pathname === "/api/players") return json(res, 200, repository.players(url.searchParams.get("q") || "", page));
      const playerMatch = url.pathname.match(/^\/api\/players\/([^/]+)$/);
      if (req.method === "GET" && playerMatch) {
        const player = repository.player(decodeURIComponent(playerMatch[1]));
        return player ? json(res, 200, player) : json(res, 404, { error: "玩家不存在" });
      }
      if (req.method === "POST" && playerMatch) {
        const playerId = decodeURIComponent(playerMatch[1]);
        const body = await jsonBody(req);
        requireReason(body.reason);
        const result = applyPlayerAction(playerId, body);
        return json(res, 200, result);
      }
      if (req.method === "GET" && url.pathname === "/api/transactions") return json(res, 200, repository.transactions(page));
      if (req.method === "GET" && url.pathname === "/api/audits") return json(res, 200, repository.audits(page));
      if (req.method === "GET" && url.pathname === "/api/matches") return json(res, 200, repository.matches(page));
      if (req.method === "GET" && url.pathname === "/api/replays") return json(res, 200, repository.replays(page));
      if (req.method === "GET" && url.pathname === "/api/server-status") {
        return json(res, 200, { game_health: await gameStatus(), ...(await serverStatus()), admin: { online: true, uptime_seconds: Math.floor(process.uptime()), memory_bytes: process.memoryUsage().rss } });
      }
      if (req.method === "POST" && url.pathname === "/api/backup") {
        const filename = `texas-${new Date().toISOString().replace(/[:.]/g, "-")}.sqlite`;
        await db.backup(resolve(backupRoot, filename));
        return json(res, 200, { ok: true, filename });
      }
      return json(res, 404, { error: "接口不存在" });
    }
    serveStatic(url.pathname, res);
  } catch (error) {
    json(res, 400, { error: error instanceof Error ? error.message : "请求失败" });
  }
});

function applyPlayerAction(playerId: string, body: Record<string, unknown>): unknown {
  const action = String(body.action || "");
  if (action === "wallet") {
    const currency = body.currency === "gems" ? "gems" : "chips";
    return repository.adjustWallet(playerId, currency, Number(body.amount), String(body.reason));
  }
  if (action === "xp") return repository.setXp(playerId, Number(body.value), String(body.reason));
  if (action === "daily_reset") return repository.resetDaily(playerId, String(body.reason));
  if (action === "ban") return repository.moderate(playerId, true, String(body.reason));
  if (action === "unban") return repository.moderate(playerId, false, String(body.reason));
  if (action === "note") return repository.note(playerId, String(body.note || ""));
  throw new Error("未知操作");
}

async function gameStatus(): Promise<Record<string, unknown>> {
  const started = Date.now();
  try {
    const response = await fetch(healthUrl, { signal: AbortSignal.timeout(2500) });
    return { running: response.ok, status: response.status, latency_ms: Date.now() - started, url: healthUrl, pm2: "unavailable", memory: "unavailable", logs: "unavailable" };
  } catch {
    return { running: false, status: "unreachable", latency_ms: Date.now() - started, url: healthUrl, pm2: "unavailable", memory: "unavailable", logs: "unavailable" };
  }
}

function serveStatic(pathname: string, res: ServerResponse): void {
  const relative = pathname === "/" ? "index.html" : pathname.replace(/^\/+/, "");
  const path = resolve(staticRoot, relative);
  if (!path.startsWith(staticRoot) || !existsSync(path)) {
    res.writeHead(404); res.end("Not found"); return;
  }
  const type: Record<string,string> = { ".html":"text/html; charset=utf-8", ".css":"text/css; charset=utf-8", ".js":"text/javascript; charset=utf-8" };
  res.writeHead(200, { "Content-Type": type[extname(path)] || "application/octet-stream" });
  createReadStream(path).pipe(res);
}
function authorized(req: IncomingMessage): boolean {
  const token = (req.headers.cookie || "").split(";").map(v=>v.trim()).find(v=>v.startsWith("admin_session="))?.slice(14);
  return Boolean(token && sessions.has(token));
}
async function jsonBody(req: IncomingMessage): Promise<Record<string, unknown>> {
  const chunks: Buffer[] = []; let size=0;
  for await (const chunk of req) { size += chunk.length; if (size > 65536) throw new Error("请求过大"); chunks.push(chunk); }
  return JSON.parse(Buffer.concat(chunks).toString("utf8") || "{}") as Record<string, unknown>;
}
function json(res:ServerResponse,status:number,value:unknown):void { res.writeHead(status,{"Content-Type":"application/json; charset=utf-8"});res.end(JSON.stringify(value)); }
function requireReason(value:unknown):void { if(String(value||"").trim().length<3) throw new Error("原因至少需要 3 个字符"); }
function positiveInt(value:string|undefined,fallback:number):number { const n=Number(value);return Number.isInteger(n)&&n>0?n:fallback; }
function securityHeaders(res:ServerResponse):void {
  res.setHeader("Cache-Control","no-store"); res.setHeader("X-Content-Type-Options","nosniff");
  res.setHeader("X-Frame-Options","DENY"); res.setHeader("Referrer-Policy","no-referrer");
  res.setHeader("Content-Security-Policy","default-src 'self'; style-src 'self'; script-src 'self'; connect-src 'self'");
}
server.listen(port, host, () => {
  console.log(`Texas Admin listening: http://${host}:${port}`);
  console.log(`SQLite database: ${started.databasePath}`);
  console.log(`Backup directory: ${backupRoot}`);
  console.log(`Environment: ${process.env.NODE_ENV || "production"}`);
  console.log(`Pre-migration backup: ${started.preMigrationBackup}`);
});
for (const signal of ["SIGINT","SIGTERM"] as const) process.on(signal,()=>server.close(()=>{db.close();process.exit(0);}));
