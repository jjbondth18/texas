import type { WebSocket } from "ws";
import type { ClientMessage, ServerMessage } from "./protocol.js";
import { applyPlayerAction, legalActions, processAutomaticTurns } from "./betting_engine.js";
import { TableState, type Player } from "./table_state.js";

interface Client {
  id: string;
  name: string;
  ws?: WebSocket;
  roomId?: string;
}

interface Room {
  id: string;
  table: TableState;
  clients: Set<string>;
}

export class RoomManager {
  private clients = new Map<string, Client>();
  private rooms = new Map<string, Room>();
  private nextPlayerId = 1;
  private nextRoomId = 1;

  connect(ws?: WebSocket): Client {
    const client: Client = { id: `player_${this.nextPlayerId++}`, name: "Player", ws };
    this.clients.set(client.id, client);
    return client;
  }

  disconnect(playerId: string): void {
    const client = this.clients.get(playerId);
    if (!client) return;
    const room = client.roomId ? this.rooms.get(client.roomId) : undefined;
    if (room) {
      room.table.markDisconnected(playerId);
      processAutomaticTurns(room.table);
      this.broadcast(room);
    }
    client.ws = undefined;
  }

  handle(playerId: string, message: ClientMessage): void {
    const client = this.mustClient(playerId);
    if (message.type === "hello") {
      client.name = message.name || client.name || playerId;
      this.send(client, { type: "hello", request_id: message.request_id, player_id: client.id });
      return;
    }
    if (message.type === "create_room") {
      const room = this.createRoom();
      this.joinRoom(client, room.id);
      this.send(client, { type: "hello", request_id: message.request_id, room_id: room.id, player_id: client.id });
      this.broadcast(room);
      return;
    }
    const roomId = message.room_id || client.roomId;
    if (!roomId) throw new Error("room_id is required");
    const room = this.mustRoom(roomId);
    switch (message.type) {
      case "join_room":
        this.joinRoom(client, room.id);
        break;
      case "sit_down":
        room.table.sitDown(toPlayer(client), numberOr(message.seat_index, 0), numberOr(message.buy_in, 5000));
        break;
      case "leave_seat":
        room.table.leaveSeat(client.id);
        break;
      case "ready":
        room.table.setReady(client.id, message.ready ?? true);
        break;
      case "start_hand":
        room.table.startHand();
        processAutomaticTurns(room.table);
        break;
      case "player_action":
        if (!message.action) throw new Error("action is required");
        applyPlayerAction(room.table, client.id, message.action, numberOr(message.amount, 0));
        break;
      default:
        throw new Error(`unsupported message: ${message.type}`);
    }
    this.broadcast(room);
  }

  createRoom(): Room {
    const id = `room_${this.nextRoomId++}`;
    const room: Room = { id, table: new TableState(id), clients: new Set() };
    this.rooms.set(id, room);
    return room;
  }

  getRoom(roomId: string): Room | undefined {
    return this.rooms.get(roomId);
  }

  getClient(playerId: string): Client | undefined {
    return this.clients.get(playerId);
  }

  private joinRoom(client: Client, roomId: string): void {
    const room = this.mustRoom(roomId);
    client.roomId = roomId;
    room.clients.add(client.id);
  }

  private broadcast(room: Room): void {
    const snapshot = room.table.publicSnapshot();
    for (const playerId of room.clients) {
      const client = this.clients.get(playerId);
      if (!client) continue;
      this.send(client, { type: "table_snapshot", room_id: room.id, snapshot });
      const privateSnapshot = room.table.privateSnapshot(playerId, legalActions(room.table, playerId));
      if (privateSnapshot) this.send(client, { type: "private_snapshot", room_id: room.id, snapshot: privateSnapshot });
    }
  }

  private send(client: Client, message: ServerMessage): void {
    if (client.ws && client.ws.readyState === client.ws.OPEN) client.ws.send(JSON.stringify(message));
  }

  private mustClient(playerId: string): Client {
    const client = this.clients.get(playerId);
    if (!client) throw new Error("unknown client");
    return client;
  }

  private mustRoom(roomId: string): Room {
    const room = this.rooms.get(roomId);
    if (!room) throw new Error("room not found");
    return room;
  }
}

function toPlayer(client: Client): Player {
  return { id: client.id, name: client.name || client.id, connected: Boolean(client.ws) };
}

function numberOr(value: unknown, fallback: number): number {
  return Number.isFinite(Number(value)) ? Number(value) : fallback;
}
