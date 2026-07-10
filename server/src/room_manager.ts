import type { WebSocket } from "ws";
import { randomUUID } from "node:crypto";
import type { ClientMessage, PublicTableSnapshot, ServerMessage } from "./protocol.js";
import { applyPlayerAction, legalActions, processAutomaticTurns } from "./betting_engine.js";
import { settleHand } from "./showdown_engine.js";
import { TableState, type Player, type Seat } from "./table_state.js";
import { getDatabase } from "./db/database.js";
import { AvatarRepository } from "./db/avatar_repository.js";
import { LoginBonusRepository } from "./db/login_bonus_repository.js";
import { PlayerRepository } from "./db/player_repository.js";
import { IdentityRepository } from "./db/identity_repository.js";
import { ResultRepository } from "./db/result_repository.js";
import { WalletRepository } from "./db/wallet_repository.js";
import { ReplayRepository } from "./db/replay_repository.js";
import { AVATAR_CATALOG, DEFAULT_AVATAR_PRICE_CHIPS, findAvatarCatalogItem } from "./avatar_catalog.js";
import { config } from "./config.js";
import { buildEncryptedReplayDelivery, buildHandReplayRecord, generateReplayKey, replayIdFor, type EncryptedReplayDelivery } from "./replay.js";

interface Client {
  id: string;
  name: string;
  avatarId: string;
  ws?: WebSocket;
  roomId?: string;
  devSimulated?: boolean;
}

type RoomTableType = "public_chip" | "public_gem" | "private_chip" | "private_gem";
type RoomCurrency = "chips" | "gems";

interface Room {
  id: string;
  table: TableState;
  clients: Set<string>;
  tableType: RoomTableType;
  visibility: "public" | "private";
  roomCode: string;
  tableName: string;
  dealerId: string;
  smallBlind: number;
  bigBlind: number;
  buyIn: number;
  handCount: number;
  actionTimeSeconds: number;
  maxPlayers: number;
  isPublic: boolean;
  isAiWarmup: boolean;
  hostInLocalWarmup: string;
  hostPlayerId: string;
  officialHandStarted: boolean;
  sessionComplete: boolean;
  readyCountdownTimer?: ReturnType<typeof setTimeout>;
  readyCountdownToken: number;
  readyCountdownDeadlineAt?: string;
  handResultTimer?: ReturnType<typeof setTimeout>;
  handResultToken: number;
  handResultDeadlineAt?: string;
  handResultShownHandId: number;
  actionTimer?: ReturnType<typeof setTimeout>;
  actionTimerToken: number;
  actionDeadlineAt?: string;
  replayDeliveries: Map<number, EncryptedReplayDelivery>;
  createdAt: string;
}

const DEFAULT_TABLE_BUY_IN = 5000;
const DEFAULT_SMALL_BLIND = 25;
const DEFAULT_BIG_BLIND = 50;
const DEFAULT_HAND_COUNT = 10;
const DEFAULT_ACTION_TIME_SECONDS = 60;
const DEFAULT_MAX_PLAYERS = 6;
const DEV_BOT_MIN_WALLET_CHIPS = 50000;
const ALLOWED_BUY_INS = new Set([5000, 10000, 20000, 50000]);
const ALLOWED_BLIND_PAIRS = new Set(["25/50", "50/100", "100/200"]);
const ALLOWED_GEM_BUY_INS = new Set([20, 50, 100, 200]);
const ALLOWED_GEM_BLIND_PAIRS = new Set(["1/2", "2/5", "5/10"]);
const ALLOWED_HAND_COUNTS = new Set([0, 5, 10, 20]);
const ALLOWED_IDENTITY_PROVIDERS = new Set(["local_dev", "steam"]);
const ACTION_TIMEOUT_MS = DEFAULT_ACTION_TIME_SECONDS * 1000;
const READY_COUNTDOWN_MS = 3000;
const HAND_RESULT_SHOWDOWN_MS = 5000;
const HAND_RESULT_FOLD_MS = 2500;
const TABLE_SEAT_JOIN_ORDER_9P = [5, 8, 2, 6, 4, 9, 1, 7, 3];
const PUBLIC_SEAT_JOIN_ORDER = TABLE_SEAT_JOIN_ORDER_9P;
const ROOM_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const DEV_SIMULATED_START_BLOCK_REASON = "Dev simulated player cannot play a real public hand. Use a second client or enable DEV controllable bot.";
const REPLAY_UNLOCK_COST_GEMS = 5;
const DEALER_IDS = [
  "dealer_01_dog",
  "dealer_02_bear",
  "dealer_03_cat",
  "dealer_04_red_panda",
  "dealer_05_armor",
  "dealer_06_sloth",
  "dealer_07_statue",
  "dealer_08_horse",
  "dealer_09_owl",
  "dealer_10_frog",
  "dealer_11_walrus",
];
const DEFAULT_DEALER_ID = "dealer_01_dog";
export class RoomManager {
  private clients = new Map<string, Client>();
  private rooms = new Map<string, Room>();
  private serverLogs: string[] = [];
  private nextPlayerId = 1;
  private nextRoomId = 1;
  private recordedHandResults = new Set<string>();
  private settledPlayerExits = new Set<string>();
  private readonly db = getDatabase();
  private readonly players = new PlayerRepository(this.db);
  private readonly identities = new IdentityRepository(this.db);
  private readonly wallets = new WalletRepository(this.db);
  private readonly avatars = new AvatarRepository(this.db);
  private readonly loginBonus = new LoginBonusRepository(this.db, this.wallets);
  private readonly results = new ResultRepository(this.db);
  private readonly replays = new ReplayRepository(this.db);

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
      if (this.shouldRefundDisconnectedBeforeOfficialHand(room, client)) {
        this.cashOut(room, client);
        this.broadcast(room);
        client.ws = undefined;
        return;
      }
      room.table.markDisconnected(playerId);
      processAutomaticTurns(room.table);
      this.rescheduleActionTimer(room);
      this.updatePublicRoomProgress(room);
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
      room.hostPlayerId = client.id;
      this.joinRoom(client, room.id);
      this.recordLog(`${client.id} created ${room.id}`);
      this.send(client, { type: "hello", request_id: message.request_id, room_id: room.id, player_id: client.id, server_player_id: client.id });
      this.broadcast(room);
      return;
    }
    if (message.type === "list_tables") {
      this.send(client, { type: "table_list", request_id: message.request_id, tables: this.publicTables(client.id) });
      return;
    }
    if (message.type === "quick_join_table") {
      const room = this.quickJoinTable(client, message);
      const table = this.tableSnapshot(room);
      this.send(client, { type: "quick_table_matched", request_id: message.request_id, room_id: room.id, table });
      this.send(client, { type: "table_list", tables: this.publicTables(client.id) });
      return;
    }
    if (message.type === "create_table") {
      const room = this.createRoom(this.tableConfigFromMessage(message));
      room.hostPlayerId = client.id;
      this.joinRoom(client, room.id);
      const table = this.tableSnapshot(room);
      this.recordLog(`${client.id} created public table ${room.id}`);
      this.send(client, { type: "table_created", request_id: message.request_id, room_id: room.id, table });
      this.send(client, { type: "table_list", tables: this.publicTables(client.id) });
      return;
    }
    if (message.type === "create_private_table") {
      const room = this.createPrivateTable(client, message);
      const table = this.tableSnapshot(room);
      this.send(client, { type: "private_table_created", request_id: message.request_id, room_id: room.id, table });
      return;
    }
    if (message.type === "join_table") {
      const room = this.rooms.get(String(message.room_id || ""));
      if (!room) throw new Error("room_not_found");
      if (!room.isPublic) throw new Error("room_not_found");
      const decision = this.publicRoomListDecision(room);
      if (!decision.include) throw new Error(decision.reason === "full" ? "table_full" : "room_not_available");
      this.joinRoom(client, room.id);
      const table = this.tableSnapshot(room);
      this.recordLog(`${client.id} joined public table ${room.id}`);
      this.send(client, { type: "table_joined", request_id: message.request_id, room_id: room.id, table });
      return;
    }
    if (message.type === "join_private_table") {
      const room = this.joinPrivateTable(client, String(message.room_code || ""));
      const table = this.tableSnapshot(room);
      this.send(client, { type: "private_table_joined", request_id: message.request_id, room_id: room.id, table });
      return;
    }
    if (message.type === "get_profile") {
      this.send(client, { type: "profile_snapshot", request_id: message.request_id, ...this.profilePayload(client.id) });
      return;
    }
    if (message.type === "claim_daily_bonus") {
      this.claimDailyBonus(client, message.request_id);
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
    if (message.type === "unlock_replay") {
      this.unlockReplay(client, message);
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
        const requestedSeatIndex = Object.prototype.hasOwnProperty.call(message, "seat_index") ? numberOr(message.seat_index, -1) : -1;
        let acceptedSeatIndex = requestedSeatIndex;
        try {
          acceptedSeatIndex = this.sitDownWithWallet(room, client, requestedSeatIndex, String(message.player_id || ""));
          this.send(client, {
            type: "sit_down_result",
            request_id: message.request_id,
            ok: true,
            room_id: room.id,
            seat_index: acceptedSeatIndex,
            player_id: client.id,
            server_player_id: client.id,
          });
          this.recordLog(`${client.id} sat in ${room.id} seat=${acceptedSeatIndex}`);
        } catch (error) {
          const reason = error instanceof Error ? error.message : String(error);
          const wallet = this.wallets.get(client.id);
          const currency = roomCurrency(room);
          this.send(client, {
            type: "sit_down_result",
            request_id: message.request_id,
            ok: false,
            room_id: room.id,
            seat_index: acceptedSeatIndex,
            player_id: client.id,
            server_player_id: client.id,
            reason,
            wallet_chips: currency === "gems" ? (wallet?.gems ?? 0) : (wallet?.chips ?? 0),
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
        if (room.sessionComplete) throw new Error("session_complete");
        room.table.setReady(client.id, message.ready ?? true, isActionPhase(room.table.phase));
        this.recordLog(`${client.id} ready=${message.ready ?? true} in ${room.id}`);
        break;
      case "restart_session":
        this.requireSeated(room, client, message, "restart_session");
        this.restartPublicSession(room, client);
        this.recordLog(`${client.id} restarted session in ${room.id}`);
        break;
      case "start_hand":
        this.requireSeated(room, client, message, "start_hand");
        this.requirePublicHandStartAllowed(room, client);
        if (!this.startOfficialPublicHand(room, "manual_start_hand")) throw new Error("session_complete");
        this.recordLog(`${client.id} started hand in ${room.id}`);
        break;
      case "start_ai_warmup": {
        try {
          this.markHostStartedLocalWarmup(room, client);
          this.send(client, { type: "start_ai_warmup_result", request_id: message.request_id, ok: true, room_id: room.id, player_id: client.id, server_player_id: client.id, is_ai_warmup: false, local_warmup: true, host_in_local_warmup: true });
          this.recordLog(`host_started_local_warmup accepted: room_id=${room.id} player_id=${client.id} real_player_count=${this.realConnectedSeatedCount(room)} seats=${this.seatDebug(room)}`);
        } catch (error) {
          const reason = error instanceof Error ? error.message : String(error);
          this.send(client, { type: "start_ai_warmup_result", request_id: message.request_id, ok: false, room_id: room.id, player_id: client.id, server_player_id: client.id, reason });
          this.recordLog(`host_started_local_warmup rejected: room_id=${room.id} player_id=${client.id} reason=${reason} real_player_count=${this.realConnectedSeatedCount(room)} state=${room.table.phase}`);
          return;
        }
        break;
      }
      case "dev_simulate_real_join":
        this.devSimulateRealJoin(room, client, String(message.player_name || "DevPlayer2"));
        this.recordLog(`dev_simulate_real_join room_id=${room.id} host_player_id=${client.id} real_player_count=${this.realConnectedSeatedCount(room)} seats=${this.seatDebug(room)}`);
        break;
      case "player_action":
        if (!message.action) throw new Error("action is required");
        this.requireSeated(room, client, message, "player_action");
        if (room.sessionComplete) throw new Error("session_complete");
        applyPlayerAction(room.table, client.id, message.action, numberOr(message.amount, 0));
        this.recordLog(`${client.id} action=${message.action} amount=${numberOr(message.amount, 0)} in ${room.id}`);
        break;
      default:
        throw new Error(`unsupported message: ${message.type}`);
    }
    this.recordHandResults(room);
    this.clearSettledExitedSeats(room);
    this.rescheduleActionTimer(room);
    this.updatePublicRoomProgress(room);
    this.broadcast(room);
  }

  createRoom(options: Partial<Pick<Room, "tableName" | "dealerId" | "smallBlind" | "bigBlind" | "buyIn" | "handCount" | "actionTimeSeconds" | "maxPlayers" | "isPublic" | "tableType" | "visibility" | "roomCode">> = {}): Room {
    const id = `room_${this.nextRoomId++}`;
    const table = new TableState(id);
    table.smallBlind = options.smallBlind ?? DEFAULT_SMALL_BLIND;
    table.bigBlind = options.bigBlind ?? DEFAULT_BIG_BLIND;
    const isPublic = options.isPublic ?? true;
    const room: Room = {
      id,
      table,
      clients: new Set(),
      tableType: options.tableType ?? (isPublic ? "public_chip" : "private_chip"),
      visibility: options.visibility ?? (isPublic ? "public" : "private"),
      roomCode: options.roomCode ?? "",
      tableName: options.tableName || `${isPublic ? "Public Table" : "Private Room"} ${this.nextRoomId - 1}`,
      dealerId: normalizeDealerId(options.dealerId || randomDealerId()),
      smallBlind: table.smallBlind,
      bigBlind: table.bigBlind,
      buyIn: options.buyIn ?? DEFAULT_TABLE_BUY_IN,
      handCount: options.handCount ?? DEFAULT_HAND_COUNT,
      actionTimeSeconds: DEFAULT_ACTION_TIME_SECONDS,
      maxPlayers: options.maxPlayers ?? DEFAULT_MAX_PLAYERS,
      isPublic,
      isAiWarmup: false,
      hostInLocalWarmup: "",
      hostPlayerId: "",
      officialHandStarted: false,
      sessionComplete: false,
      readyCountdownToken: 0,
      handResultToken: 0,
      handResultShownHandId: 0,
      actionTimerToken: 0,
      replayDeliveries: new Map(),
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
          room_code: room.roomCode,
          table_type: room.tableType,
          currency: roomCurrency(room),
          visibility: room.visibility,
          table_name: room.tableName,
          dealer_id: room.dealerId,
          small_blind: room.smallBlind,
          big_blind: room.bigBlind,
          buy_in: room.buyIn,
          hand_count: room.handCount,
          action_time_seconds: room.actionTimeSeconds,
          seated_count: this.publicSeatedCount(room),
          current_players: this.publicSeatedCount(room),
          is_public: room.isPublic,
          is_ai_warmup: room.isAiWarmup,
          host_in_local_warmup: room.hostInLocalWarmup !== "",
          host_player_id: room.hostPlayerId,
          official_hand_started: room.officialHandStarted,
          session_complete: room.sessionComplete,
          max_hands: room.handCount,
          hands_played: this.handsPlayed(room),
          current_hand_number: this.currentHandNumber(room),
          ready_count: this.publicReadyCount(room),
          ready_required_count: this.publicReadyRequiredCount(room),
          ready_countdown_deadline_at: room.readyCountdownDeadlineAt,
          hand_result_deadline_at: room.handResultDeadlineAt,
          action_timeout_ms: this.actionTimeoutMs(room),
          action_deadline_at: room.actionDeadlineAt,
          dev_simulated_player_present: this.hasUncontrolledDevSimulatedPlayer(room),
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
            ready: seat.ready,
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

  walletAudit(playerId: string): ReturnType<WalletRepository["auditWalletTransactions"]> {
    return this.wallets.auditWalletTransactions(playerId);
  }

  private joinRoom(client: Client, roomId: string): void {
    const room = this.mustRoom(roomId);
    client.roomId = roomId;
    room.clients.add(client.id);
  }

  private createPrivateTable(client: Client, message: ClientMessage): Room {
    const tableConfig = this.tableConfigFromMessage({ ...message, is_public: false });
    const roomCode = this.generateRoomCode();
    const room = this.createRoom({
      ...tableConfig,
      tableName: tableConfig.tableName || `${client.name}'s Private Room`,
      isPublic: false,
      tableType: tableConfig.tableType ?? "private_chip",
      visibility: "private",
      roomCode,
    });
    room.hostPlayerId = client.id;
    this.joinRoom(client, room.id);
    this.recordLog(`${client.id} created private table ${room.id} code=${roomCode}`);
    return room;
  }

  private joinPrivateTable(client: Client, roomCodeRaw: string): Room {
    const roomCode = normalizeRoomCode(roomCodeRaw);
    if (roomCode === "") throw new Error("room_not_found");
    const room = [...this.rooms.values()].find((candidate) => !candidate.isPublic && candidate.roomCode === roomCode);
    if (!room) throw new Error("room_not_found");
    if (room.sessionComplete || this.publicRoomState(room) === "session_complete") throw new Error("room_not_available");
    if (this.occupiedSeatCount(room) >= room.maxPlayers) throw new Error("table_full");
    this.ensureCanAffordRoom(client, room);
    this.joinRoom(client, room.id);
    this.recordLog(`${client.id} joined private table ${room.id} code=${roomCode}`);
    return room;
  }

  private generateRoomCode(): string {
    for (let attempt = 0; attempt < 50; attempt += 1) {
      let code = "";
      for (let i = 0; i < 4; i += 1) code += ROOM_CODE_ALPHABET[Math.floor(Math.random() * ROOM_CODE_ALPHABET.length)];
      if (![...this.rooms.values()].some((room) => room.roomCode === code)) return code;
    }
    return randomUUID().slice(0, 6).toUpperCase();
  }

  private quickJoinTable(client: Client, message: ClientMessage): Room {
    const tableConfig = this.tableConfigFromMessage(message);
    this.ensureCanAffordTableConfig(client, tableConfig);
    this.logQuickJoinDiagnostics(client.id, tableConfig);
    const matchedRoom = this.bestQuickJoinRoom(tableConfig);
    if (matchedRoom) {
      this.joinRoom(client, matchedRoom.id);
      this.recordLog(`${client.id} quick matched public table ${matchedRoom.id}`);
      console.log(`[QuickMatch] chosen room_id=${matchedRoom.id}`);
      return matchedRoom;
    }
    const room = this.createRoom(tableConfig);
    room.hostPlayerId = client.id;
    this.joinRoom(client, room.id);
    this.recordLog(`${client.id} quick created public table ${room.id}`);
    console.log("[QuickMatch] chosen room_id=create_new_room reason=no_matching_joinable_public_room");
    return room;
  }

  private ensureCanAffordRoom(client: Client, room: Room): void {
    this.ensureCanAffordTableConfig(client, { tableType: room.tableType, buyIn: room.buyIn });
  }

  private ensureCanAffordTableConfig(client: Client, tableConfig: Partial<Pick<Room, "tableType" | "buyIn">>): void {
    const currency = String(tableConfig.tableType || "").endsWith("_gem") ? "gems" : "chips";
    if (currency !== "gems") return;
    const buyIn = Math.floor(numberOr(tableConfig.buyIn, DEFAULT_TABLE_BUY_IN));
    this.wallets.ensure(client.id);
    const wallet = this.wallets.get(client.id);
    const balance = currency === "gems" ? (wallet?.gems ?? 0) : (wallet?.chips ?? 0);
    if (!wallet || balance < buyIn) throw new Error(currency === "gems" ? "insufficient_gems" : "insufficient_chips");
  }

  private bestQuickJoinRoom(tableConfig: Partial<Pick<Room, "tableType" | "smallBlind" | "bigBlind" | "buyIn" | "handCount">>): Room | undefined {
    return [...this.rooms.values()]
      .filter((room) => this.isQuickJoinMatch(room, tableConfig))
      .sort((a, b) => {
        const playerDelta = this.realConnectedSeatedCount(b) - this.realConnectedSeatedCount(a);
        if (playerDelta !== 0) return playerDelta;
        const createdDelta = a.createdAt.localeCompare(b.createdAt);
        if (createdDelta !== 0) return createdDelta;
        return a.id.localeCompare(b.id);
      })[0];
  }

  private isQuickJoinMatch(room: Room, tableConfig: Partial<Pick<Room, "tableType" | "smallBlind" | "bigBlind" | "buyIn" | "handCount">>): boolean {
    const listDecision = this.publicRoomListDecision(room);
    if (!listDecision.include) return false;
    if (room.tableType !== tableConfig.tableType) return false;
    if (room.buyIn !== tableConfig.buyIn || room.smallBlind !== tableConfig.smallBlind || room.bigBlind !== tableConfig.bigBlind || room.handCount !== tableConfig.handCount) return false;
    return true;
  }

  private quickJoinRejectReason(room: Room, tableConfig: Partial<Pick<Room, "tableType" | "smallBlind" | "bigBlind" | "buyIn" | "handCount">>): string {
    const listDecision = this.publicRoomListDecision(room);
    if (!listDecision.include) return listDecision.reason;
    if (room.tableType !== tableConfig.tableType) return "table_type_mismatch";
    if (room.buyIn !== tableConfig.buyIn) return "buy_in_mismatch";
    if (room.smallBlind !== tableConfig.smallBlind || room.bigBlind !== tableConfig.bigBlind) return "blinds_mismatch";
    if (room.handCount !== tableConfig.handCount) return "hand_count_mismatch";
    return "candidate";
  }

  private logQuickJoinDiagnostics(clientId: string, tableConfig: Partial<Pick<Room, "tableType" | "smallBlind" | "bigBlind" | "buyIn" | "handCount">>): void {
    const header = `[QuickMatch] request from player=${clientId} table_type=${tableConfig.tableType} currency=${tableConfig.tableType?.endsWith("_gem") ? "gems" : "chips"} selected buy_in=${tableConfig.buyIn} small_blind=${tableConfig.smallBlind} big_blind=${tableConfig.bigBlind} hand_count=${tableConfig.handCount}`;
    console.log(header);
    this.recordLog(header);
    let candidateCount = 0;
    for (const room of this.rooms.values()) {
      const reason = this.quickJoinRejectReason(room, tableConfig);
      if (reason === "candidate") candidateCount += 1;
      const line = `[QuickMatch] room ${room.id}: browser_visible=${this.publicRoomListDecision(room).include} quick_candidate=${reason === "candidate"} reason=${reason}`;
      console.log(line);
      this.recordLog(line);
    }
    const summary = `[QuickMatch] candidate_rooms=${candidateCount}`;
    console.log(summary);
    this.recordLog(summary);
  }

  private publicTables(requestingPlayerId = ""): PublicTableSnapshot[] {
    const entries = [...this.rooms.values()].map((room) => ({ room, decision: this.publicRoomListDecision(room) }));
    if (requestingPlayerId !== "") this.logTableListDiagnostics(requestingPlayerId, entries);
    return entries.filter((entry) => entry.decision.include).map((entry) => this.tableSnapshot(entry.room));
  }

  private isListedPublicChipTable(room: Room): boolean {
    return this.publicRoomListDecision(room).include;
  }

  private publicRoomListDecision(room: Room): { include: boolean; reason: string } {
    const roomState = this.publicRoomState(room);
    const currentPlayers = this.publicSeatedCount(room);
    const occupiedSeats = this.occupiedSeatCount(room);
    const hostWarming = room.hostInLocalWarmup !== "";
    if (!room.isPublic || room.visibility !== "public") return { include: false, reason: "private_room" };
    if (room.tableType !== "public_chip" && room.tableType !== "public_gem") return { include: false, reason: "not_public_table" };
    if (room.sessionComplete || roomState === "session_complete") return { include: false, reason: "session_complete" };
    if (occupiedSeats >= room.maxPlayers) return { include: false, reason: "full" };
    if (currentPlayers <= 0 && occupiedSeats > 0) return { include: false, reason: "disconnected_only" };
    if (room.isAiWarmup && !hostWarming) return { include: false, reason: "local_warmup_shadow" };
    if (hostWarming && !room.officialHandStarted) return { include: true, reason: "host_warmup_joinable" };
    if (["waiting_for_players", "waiting_ready", "ready_to_start"].includes(roomState)) return { include: true, reason: "waiting_public_room" };
    return { include: false, reason: roomState === "playing" ? "playing_not_quick_joinable" : "not_waiting_public_room" };
  }

  private logTableListDiagnostics(requestingPlayerId: string, entries: Array<{ room: Room; decision: { include: boolean; reason: string } }>): void {
    const header = `[TableList] request from player=${requestingPlayerId}`;
    const total = `[TableList] total_rooms=${entries.length}`;
    console.log(header);
    console.log(total);
    this.recordLog(header);
    this.recordLog(total);
    for (const entry of entries) {
      const room = entry.room;
      const roomState = this.publicRoomState(room);
      const line =
        `[TableList] room ${room.id}: visibility=${room.visibility} listed=${room.isPublic} table_type=${room.tableType} currency=${roomCurrency(room)} room_state=${roomState} table_state=${room.table.phase} ` +
        `host_in_local_warmup=${room.hostInLocalWarmup !== ""} is_ai_warmup=${room.isAiWarmup} official_session_started=${room.officialHandStarted} ` +
        `current_players=${this.publicSeatedCount(room)} max_players=${room.maxPlayers} buy_in=${room.buyIn} small_blind=${room.smallBlind} big_blind=${room.bigBlind} ` +
        `hand_count=${room.handCount} include=${entry.decision.include} reason=${entry.decision.reason}`;
      console.log(line);
      this.recordLog(line);
    }
  }

  private tableSnapshot(room: Room): PublicTableSnapshot {
    const roomState = this.publicRoomState(room);
    return {
      room_id: room.id,
      table_type: room.tableType,
      currency: roomCurrency(room),
      allow_quick_join: this.isQuickJoinablePublicChipTable(room),
      room_code: room.roomCode || undefined,
      visibility: room.visibility,
      table_name: room.tableName,
      dealer_id: room.dealerId,
      small_blind: room.smallBlind,
      big_blind: room.bigBlind,
      buy_in: room.buyIn,
      hand_count: room.handCount,
      action_time_seconds: room.actionTimeSeconds,
      max_hands: room.handCount,
      hands_played: this.handsPlayed(room),
      current_hand_number: this.currentHandNumber(room),
      session_complete: room.sessionComplete,
      max_players: room.maxPlayers,
      seated_count: this.publicSeatedCount(room),
      current_players: this.publicSeatedCount(room),
      hand_state: room.table.phase,
      status: roomState,
      table_state: roomState,
      room_state: roomState,
      is_ai_warmup: room.isAiWarmup,
      host_in_local_warmup: room.hostInLocalWarmup !== "",
      host_player_id: room.hostPlayerId,
      official_hand_started: room.officialHandStarted,
      ready_count: this.publicReadyCount(room),
      ready_required_count: this.publicReadyRequiredCount(room),
      ready_countdown_deadline_at: room.readyCountdownDeadlineAt,
      hand_result_deadline_at: room.handResultDeadlineAt,
      action_timeout_ms: this.actionTimeoutMs(room),
      action_deadline_at: room.actionDeadlineAt,
      dev_simulated_player_present: this.hasUncontrolledDevSimulatedPlayer(room),
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

  private isQuickJoinablePublicChipTable(room: Room): boolean {
    return this.publicRoomListDecision(room).include;
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
    const dailyStatus = this.loginBonus.status(client.id);
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
      daily_bonus_status: dailyStatus,
      warning: avatarId !== requestedAvatarId ? `avatar ${requestedAvatarId} is not unlocked; using default` : undefined,
    };
  }

  private profilePayload(playerId: string): Pick<ServerMessage, "profile" | "wallet" | "unlocked_avatar_ids" | "daily_bonus_status"> {
    const profile = this.players.find(playerId);
    const wallet = this.wallets.get(playerId);
    return {
      profile,
      wallet,
      unlocked_avatar_ids: this.avatars.getUnlockedAvatars(playerId),
      daily_bonus_status: this.loginBonus.status(playerId),
    };
  }

  private claimDailyBonus(client: Client, requestId?: string): void {
    const statusBefore = this.loginBonus.status(client.id);
    const walletBefore = this.wallets.get(client.id);
    console.log(
      `[DailyBonus] claim request player_id=${client.id}`,
    );
    console.log(
      `[DailyBonus] before chips=${walletBefore?.chips ?? "missing"} gems=${walletBefore?.gems ?? "missing"} xp=client_local`,
    );
    console.log(
      `[DailyBonus] status before: cycle_day=${statusBefore.cycle_day} claim_count=${statusBefore.claim_count} already_claimed_today=${statusBefore.already_claimed_today} can_claim_today=${statusBefore.can_claim_today}`,
    );
    const daily = this.loginBonus.claimToday(client.id);
    const walletAfter = this.wallets.get(client.id);
    const audit = this.loginBonus.auditDailyBonus(client.id);
    console.log(
      `[DailyBonus] rewards: chips=${daily.awarded_chips} xp=${daily.awarded_xp} gems=${daily.awarded_gems}`,
    );
    console.log(
      `[DailyBonus] after chips=${walletAfter?.chips ?? "missing"} gems=${walletAfter?.gems ?? "missing"} xp=client_local`,
    );
    console.log(
      `[DailyBonus] status after: cycle_day=${daily.status.cycle_day} claim_count=${daily.status.claim_count} already_claimed_today=${daily.status.already_claimed_today}`,
    );
    if (audit.claimedWithoutRewardTransaction) {
      console.warn(`[DailyBonusAudit] claimed without reward transaction player_id=${client.id}`);
    }
    const payload = {
      type: "daily_bonus_result" as const,
      request_id: requestId,
      ok: daily.daily_login_awarded,
      player_id: client.id,
      server_player_id: client.id,
      reason: daily.daily_login_awarded ? "" : "already_claimed_today",
      daily_login_awarded: daily.daily_login_awarded,
      awarded_chips: daily.awarded_chips,
      awarded_xp: daily.awarded_xp,
      awarded_gems: daily.awarded_gems,
      daily_bonus_day: daily.reward_day,
      daily_bonus_status: daily.status,
      ...this.profilePayload(client.id),
    };
    console.log(
      `[DailyBonus] response wallet chips=${payload.wallet?.chips ?? "missing"} gems=${payload.wallet?.gems ?? "missing"} xp=${daily.awarded_xp}`,
    );
    this.send(client, payload);
  }

  private buyAvatar(client: Client, avatarIdRaw: string): void {
    const avatarId = normalizeAvatarId(avatarIdRaw);
    const item = findAvatarCatalogItem(avatarId);
    if (!item) throw new Error("avatar_not_found");
    if (this.avatars.hasAvatar(client.id, avatarId)) throw new Error("already_unlocked");
    this.wallets.ensure(client.id);
    const wallet = this.wallets.get(client.id);
    if (!wallet) throw new Error("wallet not found");
    const priceChips = item.price_chips > 0 ? item.price_chips : DEFAULT_AVATAR_PRICE_CHIPS;
    if (wallet.chips < priceChips) throw new Error("insufficient_chips");
    this.wallets.deductChips(client.id, priceChips, { reason: "avatar_purchase" });
    this.avatars.unlockAvatar(client.id, avatarId);
    const profile = this.players.setAvatar(client.id, avatarId);
    client.avatarId = profile.avatar_id;
    this.send(client, { type: "profile_snapshot", player_id: client.id, room_id: client.roomId, ...this.profilePayload(client.id) });
  }

  private selectAvatar(client: Client, avatarIdRaw: string): void {
    const avatarId = normalizeAvatarId(avatarIdRaw);
    if (!findAvatarCatalogItem(avatarId)) throw new Error("avatar_not_found");
    if (!this.avatars.hasAvatar(client.id, avatarId)) throw new Error("avatar_not_unlocked");
    const profile = this.players.setAvatar(client.id, avatarId);
    client.avatarId = profile.avatar_id;
    this.send(client, { type: "profile_snapshot", player_id: client.id, room_id: client.roomId, ...this.profilePayload(client.id) });
  }

  private unlockReplay(client: Client, message: ClientMessage): void {
    const replayId = String(message.replay_id || "").trim();
    if (replayId === "") throw new Error("replay_not_found");
    const result = this.db.transaction(() => {
      const replay = this.replays.getReplayIndex(replayId);
      if (!replay) throw new Error("replay_not_found");
      if (!this.replays.isParticipant(replayId, client.id)) throw new Error("replay_access_denied");
      const key = this.replays.getReplayKey(replayId);
      if (!key) throw new Error("replay_key_missing");
      const existing = this.replays.getUnlock(replayId, client.id);
      if (existing) {
        return {
          replay,
          key,
          wallet: this.wallets.get(client.id) ?? this.wallets.ensure(client.id),
          alreadyUnlocked: true,
        };
      }
      const wallet = this.wallets.get(client.id) ?? this.wallets.ensure(client.id);
      if (wallet.gems < REPLAY_UNLOCK_COST_GEMS) throw new Error("insufficient_gems");
      const updatedWallet = this.wallets.deductGems(client.id, REPLAY_UNLOCK_COST_GEMS, {
        reason: "replay_unlock",
        relatedRoomId: replay.room_id,
        relatedHandId: replay.hand_id,
      });
      this.replays.recordUnlock(replayId, client.id, REPLAY_UNLOCK_COST_GEMS, "gems");
      return { replay, key, wallet: updatedWallet, alreadyUnlocked: false };
    })();
    this.send(client, {
      type: "replay_unlocked",
      request_id: message.request_id,
      player_id: client.id,
      server_player_id: client.id,
      replay_id: replayId,
      replay_key: result.key.key_material,
      key_version: result.key.key_version,
      checksum: result.replay.checksum,
      already_unlocked: result.alreadyUnlocked,
      wallet: result.wallet,
    });
    this.send(client, { type: "wallet_snapshot", request_id: message.request_id, player_id: client.id, wallet: result.wallet });
  }

  private markHostStartedLocalWarmup(room: Room, client: Client): void {
    const requestingSeat = room.table.getSeatByPlayer(client.id);
    const realCount = this.realConnectedSeatedCount(room);
    const allowed = room.isPublic && Boolean(requestingSeat) && room.table.phase === "waiting" && realCount === 1 && !room.isAiWarmup;
    this.recordLog(`host_started_local_warmup requested: room_id=${room.id} player_id=${client.id} real_player_count=${realCount} state=${room.table.phase} allowed=${allowed}`);
    if (!room.isPublic) throw new Error("not_public_table");
    if (!requestingSeat) throw new Error("not_seated");
    if (room.hostInLocalWarmup === client.id) return;
    if (!["waiting", "hand_over"].includes(room.table.phase)) throw new Error("already_playing");
    if (room.table.phase !== "waiting") throw new Error("not_waiting");
    if (realCount !== 1) throw new Error("too_many_real_players");
    room.hostInLocalWarmup = client.id;
    room.isAiWarmup = false;
    room.table.addAction({ type: "system", action: "local_warmup", message: `${client.name} started local AI warm-up. Public room remains open for real players.` });
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

  private devSimulateRealJoin(room: Room, hostClient: Client, playerNameRaw: string): void {
    if (config.nodeEnv === "production" || !config.allowMockPurchases) throw new Error("dev_command_disabled");
    if (!room.isPublic) throw new Error("not_public_table");
    if (room.hostInLocalWarmup !== hostClient.id) throw new Error("not_waiting");
    if (this.realConnectedSeatedCount(room) !== 1) throw new Error("too_many_real_players");
    const seat = room.table.seats.find((candidate) => candidate.playerId === "");
    if (!seat) throw new Error("table_full");
    const playerName = playerNameRaw.trim().slice(0, 32) || "DevPlayer2";
    const simulatedId = `dev_real_${randomUUID()}`;
    const simulatedClient: Client = {
      id: simulatedId,
      name: playerName,
      avatarId: "default",
      roomId: room.id,
      devSimulated: true,
    };
    this.clients.set(simulatedId, simulatedClient);
    room.clients.add(simulatedId);
    room.table.sitDown(toPlayer(simulatedClient), seat.seatIndex, room.buyIn);
    const hostId = room.hostInLocalWarmup;
    room.hostInLocalWarmup = "";
    room.isAiWarmup = false;
    room.table.addAction({ type: "system", action: "real_player_joined", message: "Dev simulated real player joined. Return from local AI warm-up to public table." });
    this.recordLog(`real_player_joined_interrupts_local_warmup room_id=${room.id} host_player_id=${hostId} joined_player_id=${simulatedId} simulated=true`);
  }

  private sitDownWithWallet(room: Room, client: Client, requestedSeatIndex: number, payloadPlayerId = ""): number {
    const existingSeat = room.table.getSeatByPlayer(client.id);
    if (existingSeat) {
      this.recordLog(`sit_down idempotent room_id=${room.id} connection_player_id=${client.id} seat_index=${existingSeat.seatIndex}`);
      return existingSeat.seatIndex;
    }
    if (this.occupiedSeatCount(room) >= room.maxPlayers) throw new Error("table_full");
    const seat = requestedSeatIndex < 0 ? this.firstAvailablePublicSeat(room) : room.table.getSeat(requestedSeatIndex);
    if (!seat || seat.playerId) throw new Error("seat is not available");
    const seatIndex = seat.seatIndex;
    this.wallets.ensure(client.id);
    const wallet = this.wallets.get(client.id);
    const currency = roomCurrency(room);
    const walletBalance = currency === "gems" ? (wallet?.gems ?? 0) : (wallet?.chips ?? 0);
    if (!wallet || walletBalance < room.buyIn) throw new Error(currency === "gems" ? "insufficient_gems" : "insufficient_chips");
    if (currency === "gems") {
      this.wallets.deductGems(client.id, room.buyIn, { reason: "gem_table_buy_in", relatedRoomId: room.id });
    } else {
      this.wallets.deductChips(client.id, room.buyIn, { reason: "table_buy_in", relatedRoomId: room.id });
    }
    if (room.hostPlayerId === "") room.hostPlayerId = client.id;
    room.table.sitDown(toPlayer(client), seatIndex, room.buyIn);
    if (room.hostInLocalWarmup !== "" && this.realConnectedSeatedCount(room) >= 2) {
      const hostId = room.hostInLocalWarmup;
      room.hostInLocalWarmup = "";
      room.table.addAction({ type: "system", action: "real_player_joined", message: "Real player joined. Return from local AI warm-up to public table." });
      this.recordLog(`real_player_joined_interrupts_local_warmup room_id=${room.id} host_player_id=${hostId} joined_player_id=${client.id}`);
    }
    const occupiedCount = this.occupiedSeatCount(room);
    const acceptedSeat = room.table.getSeat(seatIndex);
    this.recordLog(
      `sit_down accepted room_id=${room.id} connection_player_id=${client.id} payload_player_id=${payloadPlayerId || "-"} requested_seat_index=${requestedSeatIndex} seat_index=${seatIndex} seat_player_id=${acceptedSeat?.playerId || "-"} occupied_count=${occupiedCount}`,
    );
    this.sendWalletSnapshot(client, room.id);
    return seatIndex;
  }

  private firstAvailablePublicSeat(room: Room) {
    if (!this.isManagedChipRoom(room)) return room.table.seats.find((candidate) => candidate.playerId === "");
    for (const seatIndex of PUBLIC_SEAT_JOIN_ORDER) {
      const seat = room.table.getSeat(seatIndex);
      if (seat && seat.playerId === "") return seat;
    }
    return room.table.seats.find((candidate) => candidate.playerId === "");
  }

  private isManagedChipRoom(room: Room): boolean {
    return room.tableType === "public_chip" || room.tableType === "private_chip" || room.tableType === "public_gem" || room.tableType === "private_gem";
  }

  private requireSeated(room: Room, client: Client, message: ClientMessage, command: string): void {
    if (room.table.getSeatByPlayer(client.id)) return;
    this.recordNotSeated(room, client, message, command);
    throw new Error("player is not seated");
  }

  private requirePublicHandStartAllowed(room: Room, client: Client): void {
    if (!this.isManagedChipRoom(room)) return;
    if (room.hostPlayerId === "") room.hostPlayerId = client.id;
    if (client.id !== room.hostPlayerId) throw new Error("not_host");
    if (room.sessionComplete) throw new Error("session_complete");
    if (this.publicReadyRequiredCount(room) < 2) throw new Error("not_enough_players");
    if (this.hasUncontrolledDevSimulatedPlayer(room)) throw new Error(DEV_SIMULATED_START_BLOCK_REASON);
    if (room.isAiWarmup) throw new Error("already_playing");
    if (!["waiting", "hand_over"].includes(room.table.phase)) throw new Error("already_playing");
    if (!this.canStartPublicCountdown(room)) throw new Error("not_ready_to_start");
  }

  private publicReadySeats(room: Room) {
    return room.table.seats.filter((seat) => seat.playerId && !seat.isAi && !seat.warmupAi && !seat.disconnected && seat.chips > 0 && !["empty", "sit_out"].includes(seat.status));
  }

  private publicReadyCandidates(room: Room) {
    return this.publicReadySeats(room).filter((seat) => seat.ready);
  }

  private publicReadyRequiredCount(room: Room): number {
    return this.publicReadySeats(room).length;
  }

  private publicReadyCount(room: Room): number {
    return this.publicReadySeats(room).filter((seat) => seat.ready).length;
  }

  private isUnlimitedSession(room: Room): boolean {
    return room.handCount <= 0;
  }

  private currentHandNumber(room: Room): number {
    return Math.max(0, room.table.handId);
  }

  private handsPlayed(room: Room): number {
    if (room.table.handId <= 0) return 0;
    if (room.table.phase === "hand_over" || room.table.phase === "session_complete" || room.sessionComplete) return room.table.handId;
    if (isActionPhase(room.table.phase) || room.table.phase === "showdown") return Math.max(0, room.table.handId - 1);
    return room.table.handId;
  }

  private canStartAnotherSessionHand(room: Room): boolean {
    return this.isUnlimitedSession(room) || room.table.handId < room.handCount;
  }

  private hasReachedHandLimit(room: Room): boolean {
    return !this.isUnlimitedSession(room) && this.handsPlayed(room) >= room.handCount;
  }

  private canStartPublicCountdown(room: Room): boolean {
    if (!this.isManagedChipRoom(room)) return false;
    if (room.sessionComplete || !this.canStartAnotherSessionHand(room)) return false;
    if (room.isAiWarmup || this.hasUncontrolledDevSimulatedPlayer(room)) return false;
    if (!["waiting", "hand_over"].includes(room.table.phase)) return false;
    if (room.handResultTimer) return false;
    if (room.officialHandStarted && room.handResultShownHandId === room.table.handId) return false;
    const seats = this.publicReadySeats(room);
    if (seats.length < 2) return false;
    return seats.every((seat) => seat.ready);
  }

  private canAutoContinuePublicHand(room: Room): boolean {
    if (!this.isManagedChipRoom(room) || !room.officialHandStarted) return false;
    if (room.sessionComplete || !this.canStartAnotherSessionHand(room)) return false;
    if (room.isAiWarmup || this.hasUncontrolledDevSimulatedPlayer(room)) return false;
    if (!["waiting", "hand_over"].includes(room.table.phase)) return false;
    if (room.handResultTimer) return false;
    return this.publicReadyCandidates(room).length >= 2;
  }

  private updatePublicRoomProgress(room: Room): void {
    if (!this.isManagedChipRoom(room)) return;
    if (room.sessionComplete) {
      this.clearReadyCountdown(room);
      this.clearHandResultTimer(room);
      this.clearActionTimer(room);
      return;
    }
    if (isActionPhase(room.table.phase)) {
      this.clearReadyCountdown(room);
      return;
    }
    if (room.table.phase === "hand_over" && room.officialHandStarted) {
      this.clearReadyCountdown(room);
      if (room.handResultShownHandId !== room.table.handId) {
        this.scheduleHandResultTransition(room);
      } else if (this.hasReachedHandLimit(room)) {
        this.completePublicSession(room);
      } else if (this.canAutoContinuePublicHand(room)) {
        this.startOfficialPublicHand(room, "auto_next_hand");
        this.recordHandResults(room);
        this.rescheduleActionTimer(room);
      }
      return;
    }
    if (this.canStartPublicCountdown(room)) {
      this.scheduleReadyCountdown(room);
    } else {
      this.clearReadyCountdown(room);
    }
  }

  private scheduleReadyCountdown(room: Room): void {
    if (room.readyCountdownTimer) return;
    room.readyCountdownToken += 1;
    const token = room.readyCountdownToken;
    room.readyCountdownDeadlineAt = new Date(Date.now() + READY_COUNTDOWN_MS).toISOString();
    room.table.addAction({ type: "system", action: "ready_countdown", message: "All players ready. Starting in 3..." });
    room.readyCountdownTimer = setTimeout(() => this.handleReadyCountdown(room.id, token), READY_COUNTDOWN_MS);
    (room.readyCountdownTimer as { unref?: () => void }).unref?.();
  }

  private clearReadyCountdown(room: Room): void {
    if (room.readyCountdownTimer) clearTimeout(room.readyCountdownTimer);
    room.readyCountdownTimer = undefined;
    room.readyCountdownDeadlineAt = undefined;
    room.readyCountdownToken += 1;
  }

  private handleReadyCountdown(roomId: string, token: number): void {
    const room = this.rooms.get(roomId);
    if (!room || token !== room.readyCountdownToken) return;
    room.readyCountdownTimer = undefined;
    room.readyCountdownDeadlineAt = undefined;
    if (!this.canStartPublicCountdown(room)) {
      this.broadcast(room);
      return;
    }
    if (this.startOfficialPublicHand(room, "ready_countdown")) {
      this.recordHandResults(room);
      this.rescheduleActionTimer(room);
    }
    this.broadcast(room);
  }

  private startOfficialPublicHand(room: Room, reason: string): boolean {
    if (room.sessionComplete || !this.canStartAnotherSessionHand(room)) {
      this.completePublicSession(room);
      return false;
    }
    this.clearReadyCountdown(room);
    this.clearHandResultTimer(room);
    room.table.startHand(Date.now(), this.isManagedChipRoom(room));
    room.officialHandStarted = true;
    processAutomaticTurns(room.table);
    this.recordLog(`chip_hand_started room_id=${room.id} reason=${reason} hand_id=${room.table.handId}`);
    return true;
  }

  private scheduleHandResultTransition(room: Room): void {
    if (room.handResultTimer) return;
    room.handResultToken += 1;
    const token = room.handResultToken;
    const delay = this.handResultDelayMs(room);
    room.handResultDeadlineAt = new Date(Date.now() + delay).toISOString();
    room.handResultTimer = setTimeout(() => this.handleHandResultComplete(room.id, token), delay);
    (room.handResultTimer as { unref?: () => void }).unref?.();
  }

  private clearHandResultTimer(room: Room): void {
    if (room.handResultTimer) clearTimeout(room.handResultTimer);
    room.handResultTimer = undefined;
    room.handResultDeadlineAt = undefined;
    room.handResultToken += 1;
  }

  private handResultDelayMs(room: Room): number {
    const showdown = room.table.recentActions.some((entry) => entry.hand_id === room.table.handId && (entry.action === "showdown" || entry.type === "winner" || entry.message === "Showdown."));
    return showdown ? HAND_RESULT_SHOWDOWN_MS : HAND_RESULT_FOLD_MS;
  }

  private handleHandResultComplete(roomId: string, token: number): void {
    const room = this.rooms.get(roomId);
    if (!room || token !== room.handResultToken) return;
    room.handResultTimer = undefined;
    room.handResultDeadlineAt = undefined;
    room.handResultShownHandId = room.table.handId;
    if (this.hasReachedHandLimit(room)) {
      this.completePublicSession(room);
    } else if (this.canStartPublicCountdown(room)) {
      this.startOfficialPublicHand(room, "auto_next_hand");
      this.recordHandResults(room);
      this.rescheduleActionTimer(room);
    } else if (this.canAutoContinuePublicHand(room)) {
      this.startOfficialPublicHand(room, "auto_next_hand");
      this.recordHandResults(room);
      this.rescheduleActionTimer(room);
    } else {
      this.clearReadyCountdown(room);
    }
    this.broadcast(room);
  }

  private completePublicSession(room: Room): void {
    if (room.sessionComplete) return;
    room.sessionComplete = true;
    room.table.phase = "session_complete";
    room.table.currentTurnSeat = -1;
    this.clearReadyCountdown(room);
    this.clearHandResultTimer(room);
    this.clearActionTimer(room);
    room.table.addAction({
      type: "system",
      action: "session_complete",
      message: `Session complete. ${this.handsPlayed(room)}/${room.handCount} hands played.`,
    });
    this.recordLog(`session_complete room_id=${room.id} hands_played=${this.handsPlayed(room)} max_hands=${room.handCount}`);
  }

  private restartPublicSession(room: Room, client: Client): void {
    if (!this.isManagedChipRoom(room)) throw new Error("not_public_table");
    if (!room.sessionComplete) throw new Error("not_session_complete");
    if (!room.table.getSeatByPlayer(client.id)) throw new Error("not_seated");
    room.sessionComplete = false;
    room.officialHandStarted = false;
    room.handResultShownHandId = 0;
    room.hostInLocalWarmup = "";
    room.isAiWarmup = false;
    this.clearReadyCountdown(room);
    this.clearHandResultTimer(room);
    this.clearActionTimer(room);
    room.table.resetForNewSession();
  }

  private hasUncontrolledDevSimulatedPlayer(room: Room): boolean {
    return room.table.seats.some((seat) => {
      if (!seat.playerId) return false;
      const client = this.clients.get(seat.playerId);
      return Boolean(client?.devSimulated) || seat.playerId.startsWith("dev_real_");
    });
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
    const settlementKey = `${room.id}:${client.id}`;
    if (!seat) {
      if (this.settledPlayerExits.has(settlementKey)) {
        this.sendWalletSnapshot(client, room.id);
        return;
      }
      throw new Error("not_seated");
    }
    if (room.hostInLocalWarmup === client.id) room.hostInLocalWarmup = "";
    const amount = Math.max(0, Math.floor(seat.chips));
    const reason = this.exitSettlementReason(room);
    if (this.settledPlayerExits.has(settlementKey)) {
      this.recordLog(`Wallet refund skipped duplicate: reason=${reason} player_id=${client.id} room_id=${room.id}`);
      this.sendWalletSnapshot(client, room.id);
      return;
    }
    this.settledPlayerExits.add(settlementKey);
    if (this.isCashOutDuringActiveHand(room)) {
      this.foldAndZeroLeavingSeat(room, seat);
    } else {
      room.table.cashOut(client.id);
    }
    const wallet = roomCurrency(room) === "gems"
      ? this.wallets.addGems(client.id, amount, { reason, relatedRoomId: room.id, relatedHandId: room.table.handId > 0 ? String(room.table.handId) : undefined })
      : this.wallets.refundTableChips(client.id, amount, { reason, relatedRoomId: room.id, relatedHandId: room.table.handId > 0 ? String(room.table.handId) : undefined });
    const walletAfter = roomCurrency(room) === "gems" ? wallet.gems : wallet.chips;
    this.recordLog(`Wallet refund: currency=${roomCurrency(room)} reason=${reason} player_id=${client.id} amount=${amount} wallet_after=${walletAfter} room_id=${room.id}`);
    this.sendWalletSnapshot(client, room.id);
    room.clients.delete(client.id);
    client.roomId = undefined;
  }

  private shouldRefundDisconnectedBeforeOfficialHand(room: Room, client: Client): boolean {
    if (!this.isManagedChipRoom(room)) return false;
    if (room.officialHandStarted) return false;
    if (!room.table.getSeatByPlayer(client.id)) return false;
    return true;
  }

  private exitSettlementReason(room: Room): string {
    const gem = roomCurrency(room) === "gems";
    if (room.sessionComplete || room.table.phase === "session_complete") return gem ? "gem_session_complete_cash_out" : "session_complete_cash_out";
    if (this.isManagedChipRoom(room) && !room.officialHandStarted) return gem ? "gem_left_before_official_hand" : "left_before_official_hand";
    return gem ? "gem_table_cash_out" : "table_cash_out";
  }

  private isCashOutDuringActiveHand(room: Room): boolean {
    return isActionPhase(room.table.phase) || room.table.phase === "showdown";
  }

  private foldAndZeroLeavingSeat(room: Room, seat: Seat): void {
    const playerId = seat.playerId;
    const playerName = seat.name;
    const wasCurrentTurn = room.table.currentTurnSeat === seat.seatIndex;
    seat.chips = 0;
    seat.ready = false;
    seat.disconnected = true;
    if (seat.status === "playing" || seat.status === "all_in") {
      seat.status = "folded";
      seat.acted = true;
      seat.lastAction = "fold";
      seat.lastActionAmount = 0;
      room.table.addAction({
        type: "player_action",
        seat_id: seat.seatIndex,
        seat_index: seat.seatIndex,
        player_name: playerName,
        action: "fold",
        amount: 0,
        message: `${playerName} leaves during the hand and auto-folds.`,
      });
    }
    room.table.addLog(`${playerName} leaves the table. Remaining stack is cashed out; committed chips stay in the pot.`);
    if (room.table.liveSeats().length <= 1) {
      settleHand(room.table);
      return;
    }
    if (wasCurrentTurn) {
      room.table.currentTurnSeat = room.table.nextActionableSeat(seat.seatIndex);
      processAutomaticTurns(room.table);
    }
    this.recordLog(`active_hand_exit_auto_fold room_id=${room.id} player_id=${playerId} seat=${seat.seatIndex}`);
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

  private clearSettledExitedSeats(room: Room): void {
    if (this.isCashOutDuringActiveHand(room)) return;
    for (const seat of room.table.seats) {
      if (!seat.playerId) continue;
      if (this.settledPlayerExits.has(`${room.id}:${seat.playerId}`)) {
        room.table.leaveSeat(seat.playerId);
      }
    }
  }

  private broadcast(room: Room): void {
    const roomState = this.publicRoomState(room);
    const replayDelivery = room.table.phase === "hand_over" ? this.encryptedReplayDelivery(room) : undefined;
    const snapshot = {
      ...room.table.publicSnapshot(),
      table_type: room.tableType,
      currency: roomCurrency(room),
      dealer_id: room.dealerId,
      buy_in: room.buyIn,
      hand_count: room.handCount,
      action_time_seconds: room.actionTimeSeconds,
      max_hands: room.handCount,
      hands_played: this.handsPlayed(room),
      current_hand_number: this.currentHandNumber(room),
      session_complete: room.sessionComplete,
      seated_count: this.publicSeatedCount(room),
      current_players: this.publicSeatedCount(room),
      status: roomState,
      table_state: roomState,
      room_state: roomState,
      is_ai_warmup: room.isAiWarmup,
      host_in_local_warmup: room.hostInLocalWarmup !== "",
      host_player_id: room.hostPlayerId,
      official_hand_started: room.officialHandStarted,
      ready_count: this.publicReadyCount(room),
      ready_required_count: this.publicReadyRequiredCount(room),
      ready_countdown_deadline_at: room.readyCountdownDeadlineAt,
      hand_result_deadline_at: room.handResultDeadlineAt,
      action_timeout_ms: this.actionTimeoutMs(room),
      action_deadline_at: room.actionDeadlineAt,
      dev_simulated_player_present: this.hasUncontrolledDevSimulatedPlayer(room),
      ...(replayDelivery ? { replay_delivery: replayDelivery } : {}),
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

  private encryptedReplayDelivery(room: Room): EncryptedReplayDelivery {
    const cached = room.replayDeliveries.get(room.table.handId);
    if (cached) return cached;
    const replayId = replayIdFor(room.table);
    const keyMaterial = this.replays.getReplayKey(replayId)?.key_material ?? generateReplayKey();
    const record = buildHandReplayRecord(room.table, {
      roomCode: room.roomCode,
      mode: room.visibility === "private" ? "private" : "public",
      tableType: room.tableType,
      currency: roomCurrency(room),
      dealerId: room.dealerId,
      maxHands: room.handCount,
    });
    record.replay_id = replayId;
    const delivery = buildEncryptedReplayDelivery(record, keyMaterial);
    const createdAt = delivery.metadata.created_at;
    this.replays.saveReplayIndex({
      replay_id: replayId,
      hand_id: delivery.metadata.hand_id,
      room_id: room.id,
      room_code: room.roomCode,
      table_type: room.tableType,
      currency: roomCurrency(room),
      created_at: createdAt,
      checksum: delivery.checksum,
      schema_version: delivery.metadata.schema_version,
    });
    this.replays.saveParticipants(
      replayId,
      room.table.seats
        .filter((seat) => seat.playerId !== "")
        .map((seat) => ({ player_id: seat.playerId, seat_index: seat.seatIndex })),
    );
    this.replays.saveReplayKey({ replay_id: replayId, key_material: keyMaterial, key_version: delivery.key_version, created_at: createdAt });
    room.replayDeliveries.set(room.table.handId, delivery);
    return delivery;
  }

  private rescheduleActionTimer(room: Room): void {
    this.clearActionTimer(room);
    if (!isActionPhase(room.table.phase)) return;
    const seat = room.table.getSeat(room.table.currentTurnSeat);
    if (!seat || !seat.playerId || seat.status !== "playing") return;
    if (seat.isAi || seat.warmupAi || seat.disconnected) return;
    room.actionTimerToken += 1;
    const token = room.actionTimerToken;
    const timeoutMs = this.actionTimeoutMs(room);
    room.actionDeadlineAt = new Date(Date.now() + timeoutMs).toISOString();
    room.actionTimer = setTimeout(() => this.handleActionTimeout(room.id, token), timeoutMs);
    (room.actionTimer as { unref?: () => void }).unref?.();
  }

  private clearActionTimer(room: Room): void {
    if (room.actionTimer) clearTimeout(room.actionTimer);
    room.actionTimer = undefined;
    room.actionDeadlineAt = undefined;
  }

  private actionTimeoutMs(room: Room): number {
    if (!Number.isFinite(room.actionTimeSeconds)) return ACTION_TIMEOUT_MS;
    const configuredSeconds = room.actionTimeSeconds;
    return Math.max(1, Math.floor(configuredSeconds)) * 1000;
  }

  private handleActionTimeout(roomId: string, token: number): void {
    const room = this.rooms.get(roomId);
    if (!room || token !== room.actionTimerToken) return;
    room.actionTimer = undefined;
    room.actionDeadlineAt = undefined;
    if (!isActionPhase(room.table.phase)) return;
    const seat = room.table.getSeat(room.table.currentTurnSeat);
    if (!seat || !seat.playerId || seat.status !== "playing") return;
    const available = legalActions(room.table, seat.playerId);
    const canCheck = available.some((action) => action.action === "check");
    const autoAction = canCheck ? "check" : "fold";
    room.table.addAction({
      type: "system",
      seat_id: seat.seatIndex,
      seat_index: seat.seatIndex,
      player_name: seat.name,
      action: "timeout",
      message: `${seat.name} timed out. Auto-${autoAction === "check" ? "check" : "fold"}.`,
    });
    try {
      applyPlayerAction(room.table, seat.playerId, autoAction);
      processAutomaticTurns(room.table);
      this.recordLog(`action_timeout room_id=${room.id} player_id=${seat.playerId} seat=${seat.seatIndex} auto_action=${autoAction}`);
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error);
      this.recordLog(`action_timeout_failed room_id=${room.id} player_id=${seat.playerId} reason=${reason}`);
    }
    this.rescheduleActionTimer(room);
    this.recordHandResults(room);
    this.updatePublicRoomProgress(room);
    this.broadcast(room);
  }

  private send(client: Client, message: ServerMessage): void {
    if (client.ws && client.ws.readyState === client.ws.OPEN) client.ws.send(JSON.stringify(message));
  }

  private sendWalletSnapshot(client: Client, roomId?: string): void {
    const wallet = this.wallets.get(client.id);
    if (wallet) this.send(client, { type: "wallet_snapshot", player_id: client.id, room_id: roomId, wallet });
  }

  private seatDebug(room: Room): string {
    return `[${room.table.seats.map((seat) => `${seat.seatIndex}:${seat.playerId || "-"}:${seat.status}:${seat.chips}:${seat.warmupAi ? "warmup_ai" : seat.isAi ? "ai" : "real"}`).join(",")}]`;
  }

  private publicRoomState(room: Room): string {
    if (room.sessionComplete) return "session_complete";
    if (room.hostInLocalWarmup !== "" && !room.officialHandStarted && ["waiting", "hand_over"].includes(room.table.phase)) {
      return this.publicSeatedCount(room) < 2 ? "waiting_for_players" : "waiting_ready";
    }
    if (room.isAiWarmup) return "ai_warmup";
    if (isActionPhase(room.table.phase)) return "playing";
    if (room.table.phase === "showdown") return "hand_result";
    if (room.table.phase === "hand_over" && room.officialHandStarted) return "hand_result";
    if (room.readyCountdownTimer) return "starting_countdown";
    if (["waiting", "hand_over"].includes(room.table.phase)) return this.publicSeatedCount(room) < 2 ? "waiting_for_players" : "waiting_ready";
    return "playing";
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

  private tableConfigFromMessage(message: ClientMessage): Partial<Pick<Room, "tableName" | "tableType" | "smallBlind" | "bigBlind" | "buyIn" | "handCount" | "actionTimeSeconds" | "maxPlayers" | "isPublic">> {
    const isPublic = message.is_public ?? true;
    const tableType = normalizeTableType(String(message.table_type || ""), normalizeCurrency(String(message.currency || "")), isPublic);
    const currency = tableType.endsWith("_gem") ? "gems" : "chips";
    const buyIn = Math.floor(numberOr(message.buy_in, DEFAULT_TABLE_BUY_IN));
    const smallBlind = Math.floor(numberOr(message.small_blind, DEFAULT_SMALL_BLIND));
    const bigBlind = Math.floor(numberOr(message.big_blind, DEFAULT_BIG_BLIND));
    const handCount = normalizeHandCount(message.hand_count, DEFAULT_HAND_COUNT);
    const maxPlayers = Math.floor(numberOr(message.max_players, DEFAULT_MAX_PLAYERS));
    if (currency === "gems" ? !ALLOWED_GEM_BUY_INS.has(buyIn) : !ALLOWED_BUY_INS.has(buyIn)) throw new Error("invalid_table_config");
    if (currency === "gems" ? !ALLOWED_GEM_BLIND_PAIRS.has(`${smallBlind}/${bigBlind}`) : !ALLOWED_BLIND_PAIRS.has(`${smallBlind}/${bigBlind}`)) throw new Error("invalid_table_config");
    if (!ALLOWED_HAND_COUNTS.has(handCount)) throw new Error("invalid_table_config");
    if (maxPlayers < 2 || maxPlayers > DEFAULT_MAX_PLAYERS) throw new Error("invalid_table_config");
    return {
      tableName: String(message.table_name || "").trim() || undefined,
      tableType,
      smallBlind,
      bigBlind,
      buyIn,
      handCount,
      actionTimeSeconds: DEFAULT_ACTION_TIME_SECONDS,
      maxPlayers,
      isPublic,
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

function normalizeDealerId(value: string): string {
  const dealerId = String(value || "").trim();
  return DEALER_IDS.includes(dealerId) ? dealerId : DEFAULT_DEALER_ID;
}

function randomDealerId(): string {
  return DEALER_IDS[Math.floor(Math.random() * DEALER_IDS.length)] ?? DEFAULT_DEALER_ID;
}

function roomCurrency(room: Pick<Room, "tableType">): RoomCurrency {
  return room.tableType.endsWith("_gem") ? "gems" : "chips";
}

function normalizeCurrency(value: string): RoomCurrency | "" {
  const normalized = String(value || "").trim().toLowerCase();
  if (normalized === "gem" || normalized === "gems") return "gems";
  if (normalized === "chip" || normalized === "chips") return "chips";
  return "";
}

function normalizeTableType(value: string, currencyHint: RoomCurrency | "", isPublic: boolean): RoomTableType {
  const normalized = String(value || "").trim().toLowerCase();
  if (normalized === "public_gem" || normalized === "private_gem" || normalized === "public_chip" || normalized === "private_chip") return normalized;
  const currency = currencyHint || "chips";
  if (isPublic) return currency === "gems" ? "public_gem" : "public_chip";
  return currency === "gems" ? "private_gem" : "private_chip";
}

function normalizeRoomCode(value: string): string {
  return String(value || "").trim().replace(/\s+/g, "").toUpperCase().slice(0, 12);
}

function normalizeAvatarId(value: string): string {
  const trimmed = String(value || "").trim();
  return trimmed === "4_05" ? "default" : trimmed || "default";
}

function isActionPhase(phase: string): boolean {
  return ["preflop", "flop", "turn", "river"].includes(phase);
}
