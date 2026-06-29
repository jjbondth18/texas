import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { WebSocketServer } from "ws";
import type { ClientMessage, ServerMessage } from "./protocol.js";
import { RoomManager } from "./room_manager.js";

const port = Number(process.env.PORT ?? 8080);
const host = "127.0.0.1";
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
    try {
      const message = JSON.parse(raw.toString()) as ClientMessage;
      manager.handle(client.id, message);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      manager.recordLog(`error ${client.id}: ${errorMessage}`);
      send(ws, { type: "error", error: errorMessage, error_code: errorMessage });
    }
  });

  ws.on("close", () => manager.disconnect(client.id));
});

server.listen(port, host, () => {
  console.log(`Authoritative poker server listening on ws://${host}:${port}`);
  console.log(`Local admin debug dashboard available at http://${host}:${port}/admin`);
});

function send(ws: { send(data: string): void }, message: ServerMessage): void {
  ws.send(JSON.stringify(message));
}

function routeHttp(req: IncomingMessage, res: ServerResponse): void {
  const url = new URL(req.url ?? "/", `http://${req.headers.host ?? `${host}:${port}`}`);
  if (url.pathname === "/admin") {
    sendHtml(res, renderAdminPage());
    return;
  }
  if (url.pathname === "/admin/state") {
    sendJson(res, adminState());
    return;
  }
  sendText(res, 404, "Not found");
}

function adminState(): unknown {
  const showPrivateCards = process.env.DEV_SHOW_PRIVATE_CARDS === "true";
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
    <div class="notice">Local development only. Bound to 127.0.0.1; no production auth, billing, database, or GM tools.</div>
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
