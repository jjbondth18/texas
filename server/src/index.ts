import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { existsSync } from "node:fs";
import Database from "better-sqlite3";
import { WebSocketServer } from "ws";
import type { ClientMessage, ServerMessage } from "./protocol.js";
import { config, configWarnings, publicConfigSummary } from "./config.js";
import { databasePath } from "./db/database.js";
import { RoomManager } from "./room_manager.js";
import packageJson from "../package.json" with { type: "json" };

const SERVER_BUILD_ID = "sitdown-ack-v1";
const port = config.port;
const host = config.host;
const startedAt = Date.now();
const manager = new RoomManager();
const server = createServer((req, res) => routeHttp(req, res));
const wss = new WebSocketServer({ noServer: true });

server.on("upgrade", (req, socket, head) => {
  wss.handleUpgrade(req, socket, head, (ws) => {
    wss.emit("connection", ws, req);
  });
});

wss.on("connection", (ws) => {
  const client = manager.connect(ws);
  send(ws, { type: "hello", player_id: client.id });

  ws.on("message", (raw) => {
    let requestId: string | undefined;
    try {
      const message = JSON.parse(raw.toString()) as ClientMessage;
      requestId = message.request_id;
      manager.handle(client.id, message);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      manager.recordLog(`error ${client.id}: ${errorMessage}`);
      send(ws, { type: "error", request_id: requestId, error: errorMessage, error_code: errorMessage });
    }
  });

  ws.on("close", () => manager.disconnect(client.id));
});

server.listen(port, host, () => {
  console.log(`Authoritative poker server listening on ws://${host}:${port}`);
  console.log(`SERVER_BUILD_ID = "${SERVER_BUILD_ID}"`);
  console.log(`Server config: ${JSON.stringify(publicConfigSummary())}`);
  for (const warning of configWarnings()) console.warn(`WARNING: ${warning}`);
  if (config.adminEnabled) console.log(`Local admin debug dashboard available at http://${host}:${port}/admin`);
});

function send(ws: { send(data: string): void }, message: ServerMessage): void {
  ws.send(JSON.stringify(message));
}

function routeHttp(req: IncomingMessage, res: ServerResponse): void {
  const url = new URL(req.url ?? "/", `http://${req.headers.host ?? `${host}:${port}`}`);
  if (url.pathname.startsWith("/admin") && !canAccessAdmin(req)) {
    sendText(res, 403, "Admin dashboard is disabled or local-only.");
    return;
  }
  if (url.pathname === "/healthz") {
    sendJson(res, healthz());
    return;
  }
  if (url.pathname === "/admin") {
    sendHtml(res, renderAdminPage());
    return;
  }
  if (url.pathname === "/admin/db") {
    sendHtml(res, renderDatabaseAdminPage());
    return;
  }
  if (url.pathname === "/admin/state") {
    sendJson(res, adminState());
    return;
  }
  sendText(res, 404, "Not found");
}

function healthz(): unknown {
  return {
    ok: true,
    uptime: Math.floor((Date.now() - startedAt) / 1000),
    version: String(packageJson.version || "0.0.0"),
    env: config.nodeEnv,
  };
}

function adminState(): unknown {
  const showPrivateCards = config.devShowPrivateCards;
  return {
    uptime_seconds: Math.floor((Date.now() - startedAt) / 1000),
    dev_show_private_cards: showPrivateCards,
    ...manager.adminSnapshot(showPrivateCards),
  };
}

function renderAdminPage(): string {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Local Poker Server Admin</title>
  <style>
    :root { color-scheme: dark; font-family: Inter, Segoe UI, Arial, sans-serif; background: #101418; color: #e8eef5; }
    body { margin: 0; padding: 24px; }
    header { display: flex; align-items: baseline; justify-content: space-between; gap: 16px; margin-bottom: 18px; }
    h1 { font-size: 24px; margin: 0; }
    a { color: #79d8ff; text-decoration: none; }
    a:hover { text-decoration: underline; }
    .notice { color: #f7d774; font-size: 13px; }
    .grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; margin-bottom: 18px; }
    .metric, .room, .logs { border: 1px solid #29313b; background: #151b22; border-radius: 6px; padding: 12px; }
    .label { color: #9dacbc; font-size: 12px; text-transform: uppercase; letter-spacing: .06em; }
    .value { font-size: 22px; margin-top: 6px; }
    .room { margin-bottom: 12px; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }
    th, td { border-bottom: 1px solid #26303a; padding: 7px; text-align: left; }
    th { color: #9dacbc; font-weight: 600; }
    code, pre { font-family: Consolas, SFMono-Regular, monospace; }
    pre { white-space: pre-wrap; margin: 0; color: #cad6e2; }
    .muted { color: #9dacbc; }
  </style>
</head>
<body>
  <header>
    <h1>Local Poker Server Admin</h1>
    <div class="notice">Local development only. Bound to 127.0.0.1; no production auth, billing, database, or GM tools. <a href="/admin/db">Database Debug</a></div>
  </header>
  <section class="grid">
    <div class="metric"><div class="label">Uptime</div><div class="value" id="uptime">-</div></div>
    <div class="metric"><div class="label">WebSocket Connections</div><div class="value" id="connections">-</div></div>
    <div class="metric"><div class="label">Room Count</div><div class="value" id="rooms-count">-</div></div>
    <div class="metric"><div class="label">Private Cards</div><div class="value" id="private-cards">hidden</div></div>
  </section>
  <section id="rooms"></section>
  <section class="logs">
    <h2>Recent Server Logs</h2>
    <pre id="server-logs"></pre>
  </section>
  <script>
    const escapeHtml = (value) => String(value ?? "").replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char]));
    const cards = (items) => Array.isArray(items) ? items.map((card) => typeof card === "string" ? card : card.code).join(", ") : "";
    const seconds = (value) => {
      const total = Number(value) || 0;
      const h = Math.floor(total / 3600);
      const m = Math.floor((total % 3600) / 60);
      const s = total % 60;
      return h > 0 ? h + "h " + m + "m " + s + "s" : m + "m " + s + "s";
    };
    async function refresh() {
      const response = await fetch("/admin/state", { cache: "no-store" });
      const state = await response.json();
      document.getElementById("uptime").textContent = seconds(state.uptime_seconds);
      document.getElementById("connections").textContent = state.active_websocket_connections;
      document.getElementById("rooms-count").textContent = state.room_count;
      document.getElementById("private-cards").textContent = state.dev_show_private_cards ? "visible" : "hidden";
      document.getElementById("server-logs").textContent = (state.recent_server_logs || []).join("\\n");
      document.getElementById("rooms").innerHTML = (state.rooms || []).map((room) => renderRoom(room, state.dev_show_private_cards)).join("") || '<div class="room muted">No rooms yet.</div>';
    }
    function renderRoom(room, showPrivateCards) {
      const privateHeader = showPrivateCards ? "<th>Hole Cards</th>" : "";
      const rows = (room.seats || []).map((seat) => "<tr>"
        + "<td>" + escapeHtml(seat.seat_index) + "</td>"
        + "<td>" + escapeHtml(seat.name || seat.player_id || "-") + "</td>"
        + "<td>" + escapeHtml(seat.chips) + "</td>"
        + "<td>" + escapeHtml(seat.current_bet) + "</td>"
        + "<td>" + escapeHtml(seat.status) + "</td>"
        + "<td>" + escapeHtml(seat.disconnected) + "</td>"
        + (showPrivateCards ? "<td>" + escapeHtml(cards(seat.hole_cards)) + "</td>" : "")
        + "</tr>").join("");
      return '<article class="room">'
        + '<h2>' + escapeHtml(room.room_id) + '</h2>'
        + '<div class="muted">hand_state=' + escapeHtml(room.hand_state)
        + ' | betting_round=' + escapeHtml(room.betting_round)
        + ' | pot=' + escapeHtml(room.pot)
        + ' | side_pots=' + escapeHtml(JSON.stringify(room.side_pots || []))
        + ' | community_cards=' + escapeHtml(cards(room.community_cards))
        + ' | current_turn_seat=' + escapeHtml(room.current_turn_seat) + '</div>'
        + '<table><thead><tr><th>Seat</th><th>Player</th><th>Chips</th><th>Bet</th><th>Status</th><th>Disconnected</th>' + privateHeader + '</tr></thead><tbody>' + rows + '</tbody></table>'
        + '<h3>Recent Table Logs</h3><pre>' + escapeHtml((room.recent_table_logs || []).join("\\n")) + '</pre>'
        + '</article>';
    }
    refresh().catch(console.error);
    setInterval(() => refresh().catch(console.error), 1500);
  </script>
</body>
</html>`;
}

type AdminDbRow = Record<string, unknown>;

type AdminDbTable = {
  title: string;
  columns: string[];
  rows: AdminDbRow[];
};

function renderDatabaseAdminPage(): string {
  const dbPath = databasePath();
  const escapedPath = escapeHtml(dbPath);
  if (!existsSync(dbPath)) {
    return renderDatabaseAdminShell(
      escapedPath,
      `<section class="panel"><h2>Database Not Found</h2><p class="muted">No SQLite database exists at this path yet. Start the server and connect a client to create local development data.</p></section>`,
    );
  }

  let db: Database.Database | null = null;
  try {
    db = new Database(dbPath, { readonly: true, fileMustExist: true });
    const tables: AdminDbTable[] = [
      {
        title: "players",
        columns: ["player_id", "display_name", "avatar_id", "created_at", "updated_at", "last_login_at"],
        rows: queryRows(db, "SELECT player_id, display_name, avatar_id, created_at, updated_at, last_login_at FROM players ORDER BY updated_at DESC LIMIT 50"),
      },
      {
        title: "wallets",
        columns: ["player_id", "chips", "gems", "updated_at"],
        rows: queryRows(db, "SELECT player_id, chips, gems, updated_at FROM wallets ORDER BY updated_at DESC LIMIT 50"),
      },
      {
        title: "wallet_transactions",
        columns: ["id", "player_id", "currency", "amount", "reason", "balance_after", "related_room_id", "related_hand_id", "created_at"],
        rows: queryRows(
          db,
          "SELECT id, player_id, currency, amount, reason, balance_after, related_room_id, related_hand_id, created_at FROM wallet_transactions ORDER BY created_at DESC LIMIT 100",
        ),
      },
      {
        title: "player_identities",
        columns: ["id", "player_id", "provider", "external_id", "created_at"],
        rows: queryRows(db, "SELECT id, player_id, provider, external_id, created_at FROM player_identities ORDER BY created_at DESC LIMIT 50"),
      },
      {
        title: "daily_login_claims",
        columns: ["player_id", "claim_date", "chips_awarded", "claimed_at"],
        rows: queryRows(db, "SELECT player_id, claim_date, chips_awarded, claimed_at FROM daily_login_claims ORDER BY claimed_at DESC LIMIT 50"),
      },
      {
        title: "avatar_unlocks",
        columns: ["player_id", "avatar_id", "unlocked_at"],
        rows: queryRows(db, "SELECT player_id, avatar_id, unlocked_at FROM avatar_unlocks ORDER BY unlocked_at DESC LIMIT 50"),
      },
      {
        title: "recent hand_results",
        columns: ["id", "room_id", "hand_id", "player_id", "chip_delta", "result", "created_at"],
        rows: queryRows(
          db,
          "SELECT id, room_id, hand_id, player_id, chip_delta, result, created_at FROM table_session_results ORDER BY created_at DESC LIMIT 50",
        ),
      },
    ];
    return renderDatabaseAdminShell(escapedPath, tables.map(renderDbTable).join("\n"));
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return renderDatabaseAdminShell(escapedPath, `<section class="panel"><h2>Database Error</h2><pre>${escapeHtml(message)}</pre></section>`);
  } finally {
    if (db) db.close();
  }
}

function queryRows(db: Database.Database, sql: string): AdminDbRow[] {
  return db.prepare(sql).all() as AdminDbRow[];
}

function canAccessAdmin(req: IncomingMessage): boolean {
  if (!config.adminEnabled) return false;
  if (!config.adminLocalOnly) return true;
  const address = req.socket.remoteAddress || "";
  return address === "127.0.0.1" || address === "::1" || address === "::ffff:127.0.0.1";
}

function renderDbTable(table: AdminDbTable): string {
  const header = table.columns.map((column) => `<th>${escapeHtml(column)}</th>`).join("");
  const rows =
    table.rows
      .map((row) => `<tr>${table.columns.map((column) => `<td>${escapeHtml(formatDbValue(row[column]))}</td>`).join("")}</tr>`)
      .join("") || `<tr><td class="muted" colspan="${table.columns.length}">No rows.</td></tr>`;
  return `<section class="panel"><h2>${escapeHtml(table.title)}</h2><table><thead><tr>${header}</tr></thead><tbody>${rows}</tbody></table></section>`;
}

function renderDatabaseAdminShell(dbPath: string, content: string): string {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Local Poker Database Debug</title>
  <style>
    :root { color-scheme: dark; font-family: Inter, Segoe UI, Arial, sans-serif; background: #101418; color: #e8eef5; }
    body { margin: 0; padding: 24px; }
    header { display: flex; align-items: baseline; justify-content: space-between; gap: 16px; margin-bottom: 18px; }
    h1 { font-size: 24px; margin: 0; }
    h2 { font-size: 18px; margin: 0 0 10px; }
    a { color: #79d8ff; text-decoration: none; }
    a:hover { text-decoration: underline; }
    .notice { color: #f7d774; font-size: 13px; margin-bottom: 12px; }
    .path { color: #9dacbc; font-family: Consolas, SFMono-Regular, monospace; font-size: 12px; margin-bottom: 18px; }
    .panel { border: 1px solid #29313b; background: #151b22; border-radius: 6px; padding: 12px; margin-bottom: 14px; overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    th, td { border-bottom: 1px solid #26303a; padding: 7px; text-align: left; vertical-align: top; }
    th { color: #9dacbc; font-weight: 600; white-space: nowrap; }
    td { font-family: Consolas, SFMono-Regular, monospace; }
    pre { white-space: pre-wrap; margin: 0; color: #f3b3b3; }
    .muted { color: #9dacbc; }
  </style>
</head>
<body>
  <header>
    <h1>Local Poker Database Debug</h1>
    <a href="/admin">Back to Admin</a>
  </header>
  <div class="notice">Read-only local development page. No account edits, chip/gem changes, player deletion, database reset, billing, or GM tools.</div>
  <div class="path">Database: ${dbPath}</div>
  ${content}
</body>
</html>`;
}

function formatDbValue(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (typeof value === "object") return JSON.stringify(value);
  return String(value);
}

function escapeHtml(value: unknown): string {
  return String(value ?? "").replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char] ?? char);
}

function sendHtml(res: ServerResponse, body: string): void {
  res.writeHead(200, { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" });
  res.end(body);
}

function sendJson(res: ServerResponse, body: unknown): void {
  res.writeHead(200, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
  res.end(JSON.stringify(body, null, 2));
}

function sendText(res: ServerResponse, status: number, body: string): void {
  res.writeHead(status, { "content-type": "text/plain; charset=utf-8" });
  res.end(body);
}
