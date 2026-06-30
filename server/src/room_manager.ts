import type { WebSocket } from "ws";
import { randomUUID } from "node:crypto";
import type { ClientMessage, PublicTableSnapshot, ServerMessage } from "./protocol.js";
import { applyPlayerAction, legalActions, processAutomaticTurns } from "./betting_engine.js";
import { TableState, type Player } from "./table_state.js";
import { getDatabase } from "./db/database.js";
import { AvatarRepository } from "./db/avatar_repository.js";
import { LoginBonusRepository } from "./db/login_bonus_repository.js";
import { PlayerRepository } from "./db/player_repository.js";
import { IdentityRepository } from "./db/identity_repository.js";
import { ResultRepository } from "./db/result_repository.js";
import { WalletRepository } from "./db/wallet_repository.js";
import { AVATAR_CATALOG, findAvatarCatalogItem } from "./avatar_catalog.js";
import { config } from "./config.js";

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
  tableName: string;
  smallBlind: number;
  bigBlind: number;
  buyIn: number;
  handCount: number;
  maxPlayers: number;
  isPublic: boolean;
  isAiWarmup: boolean;
  warmupBaselineChips: Map<string, number>;
  lastWarmupResetHandId: number;
  createdAt: string;
}

const DEFAULT_TABLE_BUY_IN = 5000;
const DEFAULT_SMALL_BLIND = 25;
const DEFAULT_BIG_BLIND = 50;
const DEFAULT_HAND_COUNT = 10;
const DEFAULT_MAX_PLAYERS = 6;
const DEV_BOT_MIN_WALLET_CHIPS = 50000;
const ALLOWED_BUY_INS = new Set([5000, 10000, 20000, 50000]);
const ALLOWED_BLIND_PAIRS = new Set(["25/50", "50/100", "100/200"]);
const ALLOWED_HAND_COUNTS = new Set([0, 5, 10, 20]);
const ALLOWED_IDENTITY_PROVIDERS = new Set(["local_dev", "steam"]);

export class RoomManager {
  private clients = new Map<string, Client>();
  private rooms = new Map<string, Room>();
  private serverLogs: string[] = [];
  private nextPlayerId = 1;
  private nextRoomId = 1;
  private recordedHandResults = new Set<string>();
  private readonly db = getDatabase();
  private readonly players = new PlayerRepository(this.db);
  private readonly identities = new IdentityRepository(this.db);
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
      this.send(client, { type: "hello", request_id: message.request_id, room_id: room.id, player_id: client.id, server_player_id: client.id });
      this.broadcast(room);
      return;
    }
    if (message.type === "list_tables") {
      this.send(client, { type: "table_list", request_id: message.request_id, tables: this.publicTables() });
      return;
    }
    if (message.type === "create_table") {
      const room = this.createRoom(this.tableConfigFromMessage(message));
      this.joinRoom(client, room.id);
      const table = this.tableSnapshot(room);
      this.recordLog(`${client.id} created public table ${room.id}`);
      this.send(client, { type: "table_created", request_id: message.request_id, room_id: room.id, table });
      this.send(client, { type: "table_list", tables: this.publicTables() });
      return;
    }
    if (message.type === "join_table") {
      const room = this.rooms.get(String(message.room_id || ""));
      if (!room) throw new Error("room_not_found");
      if (this.occupiedSeatCount(room) >= room.maxPlayers) throw new Error("table_full");
      this.joinRoom(client, room.id);
      const table = this.tableSnapshot(room);
      this.recordLog(`${client.id} joined public table ${room.id}`);
      this.send(client, { type: "table_joined", request_id: message.request_id, room_id: room.id, table });
      return;
    }
    if (message.type === "get_profile") {
      this.send(client, { type: "profile_snapshot", request_id: message.request_id, ...this.profilePayload(client.id) });
      return;
    }
    if (message.type === "get_avatar_catalog") {
      this.send(client, { type: "avatar_catalog", request_id: message.request_id, avatar_catalog: AVATAR_CATALOG });
      return;
    }
    if (message.type === "buy_avatar") {
      this.buyAvatar(client, String(message.avatar_id || ""));
      this.recordLog(`${client.id} bought avatar=${normalizeAvatarId(String(message.avatar_id || ""))}`);
      this.send(client, { type: "profile_snapshot", request_id: message.request_id, ...this.profilePayload(client.id) });
      return;
    }
    if (message.type === "select_avatar") {
      this.selectAvatar(client, String(message.avatar_id || ""));
      this.recordLog(`${client.id} selected avatar=${normalizeAvatarId(String(message.avatar_id || ""))}`);
      this.send(client, { type: "profile_snapshot", request_id: message.request_id, ...this.profilePayload(client.id) });
      return;
    }
    if (message.type === "mock_purchase") {
      if (message.currency !== "chips" && message.currency !== "gems") throw new Error("invalid_amount");
      const currency = message.currency;
      const amount = numberOr(message.amount, 0);
      const wallet = this.mockPurchase(client, currency, amount);
      this.recordLog(`${client.id} mock_purchase currency=${currency} amount=${amount}`);
      this.send(client, { type: "mock_purchase_result", request_id: message.request_id, ok: true, player_id: client.id, server_player_id: client.id, currency, amount, source: "store_mock", wallet, wallet_chips: wallet.chips });
      this.send(client, { type: "wallet_snapshot", request_id: message.request_id, player_id: client.id, wallet });
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
      case "sit_down": {
        const seatIndex = numberOr(message.seat_index, 0);
        try {
          this.sitDownWithWallet(room, client, seatIndex, String(message.player_id || ""));
          this.send(client, {
            type: "sit_down_result",
            request_id: message.request_id,
            ok: true,
            room_id: room.id,
            seat_index: seatIndex,
            player_id: client.id,
            server_player_id: client.id,
          });
          this.recordLog(`${client.id} sat in ${room.id} seat=${seatIndex}`);
        } catch (error) {
          const reason = error instanceof Error ? error.message : String(error);
          const wallet = this.wallets.get(client.id);
          this.send(client, {
            type: "sit_down_result",
            request_id: message.request_id,
            ok: false,
            room_id: room.id,
            seat_index: seatIndex,
            player_id: client.id,
            server_player_id: client.id,
            reason,
            wallet_chips: wallet?.chips ?? 0,
            required_chips: room.buyIn,
          });
          throw error;
        }
        break;
      }
      case "add_table_chips":
        this.addTableChips(room, client, numberOr(message.amount, 0));
        this.recordLog(`${client.id} added table chips amount=${numberOr(message.amount, 0)} in ${room.id}`);
        break;
      case "leave_seat":
      case "cash_out":
        this.cashOut(room, client);
        this.recordLog(`${client.id} cashed out in ${room.id}`);
        break;
      case "ready":
        this.requireSeated(room, client, message, "ready");
        room.table.setReady(client.id, message.ready ?? true);
        this.recordLog(`${client.id} ready=${message.ready ?? true} in ${room.id}`);
        break;
      case "start_hand":
        this.requireSeated(room, client, message, "start_hand");
        room.table.startHand();
        processAutomaticTurns(room.table);
        this.recordLog(`${client.id} started hand in ${room.id}`);
        break;
      case "start_ai_warmup": {
        try {
          const aiCount = this.startAiWarmup(room, client);
          this.send(client, { type: "start_ai_warmup_result", request_id: message.request_id, ok: true, room_id: room.id, player_id: client.id, server_player_id: client.id, is_ai_warmup: true });
          this.recordLog(`start_ai_warmup accepted: room_id=${room.id} player_id=${client.id} warmup_ai_count=${aiCount} seats=${this.seatDebug(room)}`);
        } catch (error) {
          const reason = error instanceof Error ? error.message : String(error);
          this.send(client, { type: "start_ai_warmup_result", request_id: message.request_id, ok: false, room_id: room.id, player_id: client.id, server_player_id: client.id, reason });
          this.recordLog(`start_ai_warmup rejected: room_id=${room.id} player_id=${client.id} reason=${reason} real_player_count=${this.realConnectedSeatedCount(room)} state=${room.table.phase}`);
          return;
        }
        break;
      }
      case "player_action":
        if (!message.action) throw new Error("action is required");
        this.requireSeated(room, client, message, "player_action");
        applyPlayerAction(room.table, client.id, message.action, numberOr(message.amount, 0));
        this.recordLog(`${client.id} action=${message.action} amount=${numberOr(message.amount, 0)} in ${room.id}`);
        break;
      default:
        throw new Error(`unsupported message: ${message.type}`);
    }
    this.recordHandResults(room);
    this.broadcast(room);
  }

  createRoom(options: Partial<Pick<Room, "tableName" | "smallBlind" | "bigBlind" | "buyIn" | "handCount" | "maxPlayers" | "isPublic">> = {}): Room {
    const id = `room_${this.nextRoomId++}`;
    const table = new TableState(id);
    table.smallBlind = options.smallBlind ?? DEFAULT_SMALL_BLIND;
    table.bigBlind = options.bigBlind ?? DEFAULT_BIG_BLIND;
    const room: Room = {
      id,
      table,
      clients: new Set(),
      tableName: options.tableName || `Public Table ${this.nextRoomId - 1}`,
      smallBlind: table.smallBlind,
      bigBlind: table.bigBlind,
      buyIn: options.buyIn ?? DEFAULT_TABLE_BUY_IN,
      handCount: options.handCount ?? DEFAULT_HAND_COUNT,
      maxPlayers: options.maxPlayers ?? DEFAULT_MAX_PLAYERS,
      isPublic: options.isPublic ?? true,
      isAiWarmup: false,
      warmupBaselineChips: new Map(),
      lastWarmupResetHandId: 0,
      createdAt: new Date().toISOString(),
    };
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
      identity_count: this.identities.count(),
      total_wallet_chips: this.wallets.totalChips(),
      total_wallet_gems: this.wallets.totalGems(),
      avatar_unlock_count: this.avatars.countUnlocks(),
      room_count: this.roomCount(),
      table_list: this.publicTables(),
      rooms: [...this.rooms.values()].map((room) => {
        const snapshot = room.table.publicSnapshot();
        return {
          room_id: room.id,
          table_name: room.tableName,
          small_blind: room.smallBlind,
          big_blind: room.bigBlind,
          buy_in: room.buyIn,
          hand_count: room.handCount,
          seated_count: this.publicSeatedCount(room),
          current_players: this.publicSeatedCount(room),
          is_public: room.isPublic,
          is_ai_warmup: room.isAiWarmup,
          connected_player_ids: [...room.clients],
          hand_state: snapshot.phase,
          betting_round: snapshot.phase,
          pot: snapshot.pot,
          side_pots: snapshot.side_pots,
          community_cards: snapshot.community_cards.map((card) => card.code),
          current_turn_seat: snapshot.current_turn_seat,
          seats: room.table.seats.map((seat) => ({
            seat_index: seat.seatIndex,
            occupied: seat.playerId !== "",
            player_id: seat.playerId,
            name: seat.name,
            avatar_id: seat.avatarId,
            chips: seat.chips,
            table_chips: seat.chips,
            table_stack: seat.chips,
            current_bet: seat.currentBet,
            contribution: seat.contribution,
            status: seat.status,
            disconnected: seat.disconnected,
            connected: seat.playerId !== "" && !seat.disconnected,
            is_ai: seat.isAi,
            warmup_ai: seat.warmupAi,
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

  private publicTables(): PublicTableSnapshot[] {
    return [...this.rooms.values()].filter((room) => room.isPublic).map((room) => this.tableSnapshot(room));
  }

  private tableSnapshot(room: Room): PublicTableSnapshot {
    return {
      room_id: room.id,
      table_name: room.tableName,
      small_blind: room.smallBlind,
      big_blind: room.bigBlind,
      buy_in: room.buyIn,
      hand_count: room.handCount,
      max_players: room.maxPlayers,
      seated_count: this.publicSeatedCount(room),
      current_players: this.publicSeatedCount(room),
      hand_state: room.table.phase,
      table_state: room.isAiWarmup ? "ai_warmup" : room.table.phase,
      is_ai_warmup: room.isAiWarmup,
      is_public: room.isPublic,
      created_at: room.createdAt,
      seats: room.table.publicSnapshot().seats,
    };
  }

  private occupiedSeatCount(room: Room): number {
    return room.table.seats.filter((seat) => seat.playerId !== "").length;
  }

  private realConnectedSeatedCount(room: Room): number {
    return room.table.seats.filter((seat) => seat.playerId && !seat.isAi && !seat.warmupAi && !seat.disconnected).length;
  }

  private publicSeatedCount(room: Room): number {
    return room.table.seats.filter((seat) => seat.playerId !== "" && !seat.disconnected && !seat.isAi).length;
  }

  private handleHello(client: Client, message: ClientMessage): Omit<ServerMessage, "type" | "request_id" | "player_id"> {
    const previousId = client.id;
    const identity = this.resolveIdentity(message, previousId);
    const requestedId = identity.playerId;
    if (requestedId !== previousId) {
      this.clients.delete(previousId);
      client.id = requestedId;
      this.clients.set(client.id, client);
    }
    const displayName = String(message.player_name || message.name || client.name || client.id).trim() || client.id;
    const requestedAvatarId = normalizeAvatarId(String(message.avatar_id || client.avatarId || "default"));
    this.players.upsert(client.id, displayName, "default");
    this.wallets.ensure(client.id);
    this.identities.linkIdentity(client.id, identity.provider, identity.externalId);
    this.avatars.unlockAvatar(client.id, "default");
    const avatarId = this.avatars.hasAvatar(client.id, requestedAvatarId) ? requestedAvatarId : "default";
    const profile = this.players.upsert(client.id, displayName, avatarId);
    const daily = this.loginBonus.claimTodayIfNeeded(client.id);
    this.ensureDevBotWallet(client.id);
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

  private buyAvatar(client: Client, avatarIdRaw: string): void {
    const avatarId = normalizeAvatarId(avatarIdRaw);
    const item = findAvatarCatalogItem(avatarId);
    if (!item) throw new Error("avatar_not_found");
    if (this.avatars.hasAvatar(client.id, avatarId)) throw new Error("already_unlocked");
    this.wallets.ensure(client.id);
    const wallet = this.wallets.get(client.id);
    if (!wallet) throw new Error("wallet not found");
    if (item.currency === "chips") {
      if (wallet.chips < item.price_chips) throw new Error("insufficient_chips");
      this.wallets.deductChips(client.id, item.price_chips, { reason: "avatar_purchase" });
    } else if (item.currency === "gems") {
      if (wallet.gems < item.price_gems) throw new Error("insufficient_gems");
      this.wallets.deductGems(client.id, item.price_gems, { reason: "avatar_purchase" });
    }
    this.avatars.unlockAvatar(client.id, avatarId);
    this.sendWalletSnapshot(client, client.roomId);
  }

  private selectAvatar(client: Client, avatarIdRaw: string): void {
    const avatarId = normalizeAvatarId(avatarIdRaw);
    if (!findAvatarCatalogItem(avatarId)) throw new Error("avatar_not_found");
    if (!this.avatars.hasAvatar(client.id, avatarId)) throw new Error("avatar_not_unlocked");
    const profile = this.players.setAvatar(client.id, avatarId);
    client.avatarId = profile.avatar_id;
  }

  private startAiWarmup(room: Room, client: Client): number {
    const requestingSeat = room.table.getSeatByPlayer(client.id);
    const realCount = this.realConnectedSeatedCount(room);
    const allowed = room.isPublic && Boolean(requestingSeat) && room.table.phase === "waiting" && realCount === 1 && !room.isAiWarmup;
    this.recordLog(`start_ai_warmup requested: room_id=${room.id} player_id=${client.id} real_player_count=${realCount} state=${room.table.phase} allowed=${allowed}`);
    if (!room.isPublic) throw new Error("not_public_table");
    if (!requestingSeat) throw new Error("not_seated");
    if (room.isAiWarmup) throw new Error("already_playing");
    if (!["waiting", "hand_over"].includes(room.table.phase)) throw new Error("already_playing");
    if (room.table.phase !== "waiting") throw new Error("not_waiting");
    if (realCount !== 1) throw new Error("too_many_real_players");
    room.isAiWarmup = true;
    room.warmupBaselineChips = new Map(room.table.seats.filter((seat) => seat.playerId && !seat.isAi && !seat.warmupAi).map((seat) => [seat.playerId, seat.chips]));
    let added = 0;
    for (const seat of room.table.seats) {
      if (added >= 3) break;
      if (seat.playerId) continue;
      const player: Player = {
        id: `warmup_ai_${room.id}_${added + 1}`,
        name: `Warm-up AI ${added + 1}`,
        avatarId: "default",
        connected: true,
        isAi: true,
        warmupAi: true,
      };
      room.table.sitDown(player, seat.seatIndex, room.buyIn);
      added += 1;
    }
    if (added === 0) throw new Error("table_full");
    room.table.addAction({ type: "system", action: "ai_warmup", message: "AI WARM-UP started. Practice results will not affect account wallet." });
    room.table.startHand();
    processAutomaticTurns(room.table);
    return added;
  }

  private mockPurchase(client: Client, currency: "chips" | "gems", amount: number) {
    if (!config.allowMockPurchases) throw new Error("mock_purchase_disabled");
    const normalized = Math.floor(amount);
    if (normalized <= 0) throw new Error("invalid_amount");
    this.wallets.ensure(client.id);
    if (currency === "gems") {
      return this.wallets.addGems(client.id, normalized, { reason: "store_mock_purchase" });
    }
    return this.wallets.addChips(client.id, normalized, { reason: "store_mock_purchase" });
  }

  private sitDownWithWallet(room: Room, client: Client, seatIndex: number, payloadPlayerId = ""): void {
    const seat = room.table.getSeat(seatIndex);
    if (!seat || seat.playerId) throw new Error("seat is not available");
    this.wallets.ensure(client.id);
    const wallet = this.wallets.get(client.id);
    if (!wallet || wallet.chips < room.buyIn) throw new Error("insufficient_chips");
    this.wallets.deductChips(client.id, room.buyIn, { reason: "table_buy_in", relatedRoomId: room.id });
    room.table.sitDown(toPlayer(client), seatIndex, room.buyIn);
    const occupiedCount = this.occupiedSeatCount(room);
    const acceptedSeat = room.table.getSeat(seatIndex);
    this.recordLog(
      `sit_down accepted room_id=${room.id} connection_player_id=${client.id} payload_player_id=${payloadPlayerId || "-"} seat_index=${seatIndex} seat_player_id=${acceptedSeat?.playerId || "-"} occupied_count=${occupiedCount}`,
    );
    this.sendWalletSnapshot(client, room.id);
  }

  private requireSeated(room: Room, client: Client, message: ClientMessage, command: string): void {
    if (room.table.getSeatByPlayer(client.id)) return;
    this.recordNotSeated(room, client, message, command);
    throw new Error("player is not seated");
  }

  private recordNotSeated(room: Room, client: Client, message: ClientMessage, command: string): void {
    const seatPlayerIds = room.table.seats.map((seat) => seat.playerId || "-").join(",");
    const occupiedSeats = room.table.seats.filter((seat) => seat.playerId).map((seat) => `${seat.seatIndex}:${seat.playerId}:${seat.status}:${seat.chips}`).join(",");
    this.recordLog(
      `player is not seated command=${command} room_id=${room.id} connection_player_id=${client.id} payload_player_id=${String(message.player_id || "-")} seat_player_ids=[${seatPlayerIds}] occupied_seats=[${occupiedSeats}]`,
    );
  }

  private addTableChips(room: Room, client: Client, amount: number): void {
    const normalized = Math.floor(amount);
    if (normalized <= 0) throw new Error("invalid_amount");
    const seat = room.table.getSeatByPlayer(client.id);
    if (!seat) throw new Error("not_seated");
    if (!room.table.canMoveTableChips()) throw new Error("cannot_add_chips_during_hand");
    this.wallets.ensure(client.id);
    const wallet = this.wallets.get(client.id);
    if (!wallet || wallet.chips < normalized) throw new Error("insufficient_chips");
    this.wallets.deductChips(client.id, normalized, { reason: "add_table_chips", relatedRoomId: room.id });
    room.table.addTableChips(client.id, normalized);
    this.sendWalletSnapshot(client, room.id);
  }

  private cashOut(room: Room, client: Client): void {
    const seat = room.table.getSeatByPlayer(client.id);
    if (!seat) throw new Error("not_seated");
    if (!room.table.canMoveTableChips()) throw new Error("cannot_cash_out_during_hand");
    const result = room.table.cashOut(client.id);
    this.wallets.refundTableChips(client.id, result.amount, { reason: "table_cash_out", relatedRoomId: room.id });
    this.sendWalletSnapshot(client, room.id);
  }

  private recordHandResults(room: Room): void {
    if (room.table.phase !== "hand_over") return;
    if (room.isAiWarmup) return;
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
    this.restoreWarmupStacksIfNeeded(room);
    const snapshot = {
      ...room.table.publicSnapshot(),
      buy_in: room.buyIn,
      hand_count: room.handCount,
      seated_count: this.publicSeatedCount(room),
      current_players: this.publicSeatedCount(room),
      table_state: room.isAiWarmup ? "ai_warmup" : room.table.phase,
      is_ai_warmup: room.isAiWarmup,
      table_info: this.tableSnapshot(room),
    };
    for (const playerId of room.clients) {
      const client = this.clients.get(playerId);
      if (!client) continue;
      this.send(client, { type: "table_snapshot", room_id: room.id, snapshot });
      const wallet = this.wallets.get(playerId);
      if (wallet) this.send(client, { type: "wallet_snapshot", room_id: room.id, wallet });
      const privateSnapshot = room.table.privateSnapshot(playerId, legalActions(room.table, playerId));
      if (privateSnapshot) this.send(client, { type: "private_snapshot", room_id: room.id, snapshot: privateSnapshot });
    }
  }

  private send(client: Client, message: ServerMessage): void {
    if (client.ws && client.ws.readyState === client.ws.OPEN) client.ws.send(JSON.stringify(message));
  }

  private sendWalletSnapshot(client: Client, roomId?: string): void {
    const wallet = this.wallets.get(client.id);
    if (wallet) this.send(client, { type: "wallet_snapshot", player_id: client.id, room_id: roomId, wallet });
  }

  private restoreWarmupStacksIfNeeded(room: Room): void {
    if (!room.isAiWarmup || room.table.phase !== "hand_over" || room.lastWarmupResetHandId === room.table.handId) return;
    for (const seat of room.table.seats) {
      if (!seat.playerId || seat.warmupAi || seat.isAi) continue;
      const baseline = room.warmupBaselineChips.get(seat.playerId);
      if (baseline !== undefined) seat.chips = baseline;
    }
    room.lastWarmupResetHandId = room.table.handId;
    room.table.lastHandResults = [];
    room.table.addAction({ type: "system", message: "AI warm-up result ignored for account settlement. Table stack restored." });
  }

  private seatDebug(room: Room): string {
    return `[${room.table.seats.map((seat) => `${seat.seatIndex}:${seat.playerId || "-"}:${seat.status}:${seat.chips}:${seat.warmupAi ? "warmup_ai" : seat.isAi ? "ai" : "real"}`).join(",")}]`;
  }

  private resolveIdentity(message: ClientMessage, fallbackPlayerId: string): { provider: string; externalId: string; playerId: string } {
    const provider = normalizeIdentityProvider(String(message.auth_provider || "local_dev"));
    if (!ALLOWED_IDENTITY_PROVIDERS.has(provider)) throw new Error("invalid_identity_provider");
    const hasExternalId = Object.prototype.hasOwnProperty.call(message, "external_id");
    const rawExternalId = hasExternalId ? String(message.external_id || "") : String(message.player_id || fallbackPlayerId);
    const externalId = normalizeExternalId(rawExternalId);
    if (externalId === "") throw new Error("external_id is required");
    const existing = this.identities.findByProviderExternal(provider, externalId);
    if (existing) return { provider, externalId, playerId: existing.player_id };
    const playerId = provider === "local_dev" ? normalizePlayerId(externalId) : `player_${randomUUID()}`;
    return { provider, externalId, playerId };
  }

  private tableConfigFromMessage(message: ClientMessage): Partial<Pick<Room, "tableName" | "smallBlind" | "bigBlind" | "buyIn" | "handCount" | "maxPlayers" | "isPublic">> {
    const buyIn = Math.floor(numberOr(message.buy_in, DEFAULT_TABLE_BUY_IN));
    const smallBlind = Math.floor(numberOr(message.small_blind, DEFAULT_SMALL_BLIND));
    const bigBlind = Math.floor(numberOr(message.big_blind, DEFAULT_BIG_BLIND));
    const handCount = normalizeHandCount(message.hand_count, DEFAULT_HAND_COUNT);
    const maxPlayers = Math.floor(numberOr(message.max_players, DEFAULT_MAX_PLAYERS));
    if (!ALLOWED_BUY_INS.has(buyIn)) throw new Error("invalid_table_config");
    if (!ALLOWED_BLIND_PAIRS.has(`${smallBlind}/${bigBlind}`)) throw new Error("invalid_table_config");
    if (!ALLOWED_HAND_COUNTS.has(handCount)) throw new Error("invalid_table_config");
    if (maxPlayers < 2 || maxPlayers > DEFAULT_MAX_PLAYERS) throw new Error("invalid_table_config");
    return {
      tableName: String(message.table_name || "").trim() || undefined,
      smallBlind,
      bigBlind,
      buyIn,
      handCount,
      maxPlayers,
      isPublic: message.is_public ?? true,
    };
  }

  private ensureDevBotWallet(playerId: string): void {
    if (!playerId.startsWith("bot_") && !playerId.startsWith("LocalBot")) return;
    const wallet = this.wallets.get(playerId);
    if (!wallet || wallet.chips >= DEV_BOT_MIN_WALLET_CHIPS) return;
    this.wallets.addChips(playerId, DEV_BOT_MIN_WALLET_CHIPS - wallet.chips, { reason: "dev_bot_wallet_top_up" });
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
  return {
    id: client.id,
    name: client.name || client.id,
    connected: Boolean(client.ws),
    avatarId: client.avatarId || "default",
    isAi: client.id.startsWith("bot_") || client.id.startsWith("LocalBot"),
  };
}

function numberOr(value: unknown, fallback: number): number {
  return Number.isFinite(Number(value)) ? Number(value) : fallback;
}

function normalizeHandCount(value: unknown, fallback: number): number {
  if (value === undefined || value === null || value === "") return fallback;
  if (String(value).trim().toLowerCase() === "unlimited") return 0;
  return Math.floor(numberOr(value, fallback));
}

function normalizePlayerId(value: string): string {
  const trimmed = String(value || "").trim();
  return trimmed.replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 64) || `player_${Date.now()}`;
}

function normalizeIdentityProvider(value: string): string {
  return String(value || "").trim().toLowerCase();
}

function normalizeExternalId(value: string): string {
  return String(value || "").trim().slice(0, 128);
}

function normalizeAvatarId(value: string): string {
  const trimmed = String(value || "").trim();
  return trimmed === "4_05" ? "default" : trimmed || "default";
}
