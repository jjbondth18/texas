import { WebSocketServer } from "ws";
import type { ClientMessage, ServerMessage } from "./protocol.js";
import { RoomManager } from "./room_manager.js";

const port = Number(process.env.PORT ?? 8080);
const manager = new RoomManager();
const wss = new WebSocketServer({ host: "127.0.0.1", port });

wss.on("connection", (ws) => {
  const client = manager.connect(ws);
  send(ws, { type: "hello", player_id: client.id });

  ws.on("message", (raw) => {
    try {
      const message = JSON.parse(raw.toString()) as ClientMessage;
      manager.handle(client.id, message);
    } catch (error) {
      send(ws, { type: "error", error: error instanceof Error ? error.message : String(error) });
    }
  });

  ws.on("close", () => manager.disconnect(client.id));
});

console.log(`Authoritative poker server listening on ws://127.0.0.1:${port}`);

function send(ws: { send(data: string): void }, message: ServerMessage): void {
  ws.send(JSON.stringify(message));
}
