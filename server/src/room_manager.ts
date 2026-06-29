import type { WebSocket } from "ws";
import type { ClientMessage, ServerMessage } from "./protocol.js";
import { applyPlayerAction, legalActions, processAutomaticTurns } from "./betting_engine.js";
import { TableState, type Player } from "./table_state.js";
import { getDatabase } from "./db/database.js";
import { AvatarRepository } from "./db/avatar_repository.js";
import { LoginBonusRepository } from "./db/login_bonus_repository.js";
import { PlayerRepository } from "./db/player_repository.js";
import { ResultRepository } from "./db/result_repository.js";
import { WalletRepository } from "./db/wallet_repository.js";

interface Client {
  id: string;
  name: string;
  avatarId: string;
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
  private serverLogs: string[] = [];
  private nextPlayerId = 1;
  private nextRoomId = 1;
  private recordedHandResults = new Set<string>();
  private readonly db = getDatabase();
  private readonly players = new PlayerRepository(this.db);
  private readonly wallets = new WalletRepository(this.db);
  private readonly avatars = new AvatarRepository(this.db);
  private readonly loginBonus = new LoginBonusRepository(this.db, this.wallets);
  private readonly results = new ResultRepository(this.db);

  connect(ws?: WebSocket): Client {
    const client: Client = { id: `player_${this.nextPlayerId++}`, name: "Player", avatarId: "default", ws };
    this.clients.set(client.id, client);
    this.recordLog(`connect ${client.id}`);
    return client;
  }

  disconnect(playerId: string): void {
    const client = this.clients.get(playerId);
    if (!client) return;
    this.recordLog(`disconnect ${playerId}`);
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
      const hello = this.handleHello(client, message);
      this.recordLog(`hello ${client.id} name=${client.name}`);
      this.send(client, { type: "hello", request_id: message.request_id, player_id: client.id, server_player_id: client.id, ...hello });
      return;
    }
    if (message.type === "create_room") {
      const room = this.createRoom();
      this.joinRoom(client, room.id);
      this.recordLog(`${client.id} created ${room.id}`);
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
        this.recordLog(`${client.id} joined ${room.id}`);
        break;
      case "sit_down":
        this.sitDownWithWallet(room, client, numberOr(message.seat_index, 0), numberOr(message.buy_in, 1000));
        this.recordLog(`${client.id} sat in ${room.id} seat=${numberOr(message.seat_index, 0)}`);
        break;
      case "leave_seat":
        room.table.leaveSeat(client.id);
        this.recordLog(`${client.id} left seat in ${room.id}`);
        break;
      case "ready":
        room.table.setReady(client.id, message.ready ?? true);
        this.recordLog(`${client.id} ready=${message.ready ?? true} in ${room.id}`);
        break;
      case "start_hand":
        room.table.startHand();
        processAutomaticTurns(room.table);
        this.recordLog(`${client.id} started hand in ${room.id}`);
        break;
      case "player_action":
        if (!message.action) throw new Error("action is required");
        applyPlayerAction(room.table, client.id, message.action, numberOr(message.amount, 0));
        this.recordLog(`${client.id} action=${message.action} amount=${numberOr(message.amount, 0)} in ${room.id}`);
        break;
      case "get_profile":
        this.send(client, { type: "profile_snapshot", request_id: message.request_id, ...this.profilePayload(client.id) });
        return;
      default:
        throw new Error(`unsupported message: ${message.type}`);
    }
    this.recordHandResults(room);
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

  activeConnectionCount(): number {
    let count = 0;
    for (const client of this.clients.values()) {
      if (client.ws && client.ws.readyState === client.ws.OPEN) count += 1;
    }
    return count;
  }

  roomCount(): number {
    return this.rooms.size;
  }

  recordLog(message: string): void {
    const timestamp = new Date().toISOString();
    this.serverLogs.push(`[${timestamp}] ${message}`);
    if (this.serverLogs.length > 120) this.serverLogs = this.serverLogs.slice(-120);
  }

  adminSnapshot(showPrivateCards: boolean): Record<string, unknown> {
    return {
      active_websocket_connections: this.activeConnectionCount(),
      player_count: this.players.count(),
      total_wallet_chips: this.wallets.totalChips(),
      room_count: this.roomCount(),
      rooms: [...this.rooms.values()].map((room) => {
        const snapshot = room.table.publicSnapshot();
        return {
          room_id: room.id,
          connected_player_ids: [...room.clients],
          hand_state: snapshot.phase,
          betting_round: snapshot.phase,
          pot: snapshot.pot,
          side_pots: snapshot.side_pots,
          community_cards: snapshot.community_cards.map((card) => card.code),
          current_turn_seat: snapshot.current_turn_seat,
          seats: room.table.seats.map((seat) => ({
            seat_index: seat.seatIndex,
            player_id: seat.playerId,
            name: seat.name,
            chips: seat.chips,
            current_bet: seat.currentBet,
            contribution: seat.contribution,
            status: seat.status,
            disconnected: seat.disconnected,
            last_action: seat.lastAction,
            hole_card_count: seat.holeCards.length,
            ...(showPrivateCards ? { hole_cards: seat.holeCards.map((card) => card.code) } : {}),
          })),
          recent_table_logs: snapshot.log.slice(-20),
        };
      }),
      recent_server_logs: this.serverLogs.slice(-50),
    };
  }

  private joinRoom(client: Client, roomId: string): void {
    const room = this.mustRoom(roomId);
    client.roomId = roomId;
    room.clients.add(client.id);
  }

  private handleHello(client: Client, message: ClientMessage): Omit<ServerMessage, "type" | "request_id" | "player_id"> {
    const previousId = client.id;
    const requestedId = normalizePlayerId(message.player_id || previousId);
    if (requestedId !== previousId) {
      this.clients.delete(previousId);
      client.id = requestedId;
      this.clients.set(client.id, client);
    }
    const displayName = String(message.player_name || message.name || client.name || client.id).trim() || client.id;
    const requestedAvatarId = String(message.avatar_id || client.avatarId || "default").trim() || "default";
    this.players.upsert(client.id, displayName, "default");
    this.wallets.ensure(client.id);
    this.avatars.unlockAvatar(client.id, "default");
    const avatarId = this.avatars.hasAvatar(client.id, requestedAvatarId) ? requestedAvatarId : "default";
    const profile = this.players.upsert(client.id, displayName, avatarId);
    const daily = this.loginBonus.claimTodayIfNeeded(client.id);
    const wallet = this.wallets.get(client.id)!;
    const unlocked = this.avatars.getUnlockedAvatars(client.id);
    client.name = profile.display_name;
    client.avatarId = profile.avatar_id;
    return {
      server_player_id: client.id,
      profile,
      wallet,
      unlocked_avatar_ids: unlocked,
      daily_login_awarded: daily.daily_login_awarded,
      awarded_chips: daily.awarded_chips,
      warning: avatarId !== requestedAvatarId ? `avatar ${requestedAvatarId} is not unlocked; using default` : undefined,
    };
  }

  private profilePayload(playerId: string): Pick<ServerMessage, "profile" | "wallet" | "unlocked_avatar_ids"> {
    const profile = this.players.find(playerId);
    const wallet = this.wallets.get(playerId);
    return {
      profile,
      wallet,
      unlocked_avatar_ids: this.avatars.getUnlockedAvatars(playerId),
    };
  }

  private sitDownWithWallet(room: Room, client: Client, seatIndex: number, requestedBuyIn: number): void {
    const seat = room.table.getSeat(seatIndex);
    if (!seat || seat.playerId) throw new Error("seat is not available");
    this.wallets.ensure(client.id);
    const buyIn = Math.max(1, Math.floor(requestedBuyIn || 1000));
    this.wallets.deductChips(client.id, buyIn);
    room.table.sitDown(toPlayer(client), seatIndex, buyIn);
  }

  private recordHandResults(room: Room): void {
    if (room.table.phase !== "hand_over") return;
    const key = `${room.id}:${room.table.handId}`;
    if (this.recordedHandResults.has(key)) return;
    this.recordedHandResults.add(key);
    for (const result of room.table.lastHandResults) {
      const seat = room.table.getSeat(result.seat_index);
      if (!seat?.playerId) continue;
      this.results.recordHandResult(room.id, room.table.handId, seat.playerId, result.delta, JSON.stringify(result));
    }
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

function normalizePlayerId(value: string): string {
  const trimmed = String(value || "").trim();
  return trimmed.replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 64) || `player_${Date.now()}`;
}
