import type { WebSocket } from "ws";
import { randomUUID } from "node:crypto";
import type { ClientMessage, PrivateSnapshot, PublicTableSnapshot, ServerMessage } from "./protocol.js";
import { applyPlayerAction, legalActions, processAutomaticTurns } from "./betting_engine.js";
import { settleHand } from "./showdown_engine.js";
import { evaluateBestHand } from "./hand_evaluator.js";
import { TableState, type Player, type Seat } from "./table_state.js";
import {
  challengeCatalog,
  challengeConfigById,
  challengePayout,
  displayResultForSettlement,
  isChallengeId,
  settlementReasonText,
} from "./ai_challenge/ai_challenge_config.js";
import { decideChallengeBotAction } from "./ai_challenge/ai_challenge_policy.js";
import type {
  ChallengeBotContext,
  ChallengeBotDecision,
  ChallengeState,
  ChallengeSettlementReason,
  ChallengeSettlementResult,
} from "./ai_challenge/ai_challenge_types.js";
import { getDatabase } from "./db/database.js";
import { AvatarRepository } from "./db/avatar_repository.js";
import { LoginBonusRepository } from "./db/login_bonus_repository.js";
import { PlayerRepository } from "./db/player_repository.js";
import { IdentityRepository } from "./db/identity_repository.js";
import { ResultRepository } from "./db/result_repository.js";
import { WalletRepository } from "./db/wallet_repository.js";
import { walletHistoryEntry } from "./wallet_history.js";
import { ReplayRepository, type ReplayIndexRecord } from "./db/replay_repository.js";
import { TableBalanceRepository, type TableBalanceCurrency } from "./db/table_balance_repository.js";
import { ProfileBootstrapRepository } from "./db/profile_bootstrap_repository.js";
import { SteamPurchaseRepository, type SteamPurchaseOrderRecord } from "./db/steam_purchase_repository.js";
import { AVATAR_CATALOG, DEFAULT_AVATAR_PRICE_CHIPS, findAvatarCatalogItem } from "./avatar_catalog.js";
import { config, type SteamAuthMode, type SteamCommerceMode } from "./config.js";
import { buildEncryptedReplayDelivery, buildHandReplayRecord, generateReplayKey, replayIdFor, REPLAY_ENCRYPTION_ALGORITHM, type EncryptedReplayDelivery } from "./replay.js";
import { SteamWebApiAuthVerifier, type SteamAuthVerifier } from "./services/steam_auth_verifier.js";
import { SteamWebApiMicroTxnGateway, type SteamMicroTxnGateway } from "./services/steam_microtxn_gateway.js";
import { findStorePackage, storeCatalog } from "./store_catalog.js";
import {
  REPLAY_ECONOMY_CONFIG,
  isReplayType,
  replayTypeForOfficialTable,
  replayUnlockCost,
  replayUnlockReason,
  type ReplayType,
} from "./replay_economy.js";
import {
  PUBLIC_VIRTUAL_PLAYER_PROFILES,
  type PublicVirtualPlayerConfig,
} from "./public_virtual_players.js";
import { decideVirtualPlayerAction } from "./virtual_player_decision_gateway.js";
import { buildVirtualBotContext } from "./virtual_player_context_builder.js";
import { VirtualPlayerManager } from "./virtual_player_manager.js";
import { VirtualPlayerRepository } from "./db/virtual_player_repository.js";

interface Client {
  id: string;
  name: string;
  avatarId: string;
  authProvider?: string;
  externalId?: string;
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
  singleHumanWaitingSinceAt?: string;
  localWarmupStartedAt?: string;
  hostPlayerId: string;
  officialHandStarted: boolean;
  sessionComplete: boolean;
  mode: "public" | "ai_challenge";
  challengeId: string;
  walletImpact: boolean;
  challengePlayerId: string;
  challengeBotPlayerId: string;
  challengeSeed: number;
  challengeDecisionIndex: number;
  challengeResultSent: boolean;
  challengeState: ChallengeState;
  entryFeeCharged: boolean;
  entryFeeRefunded: boolean;
  settlementApplied: boolean;
  settlementResult: ChallengeSettlementResult | null;
  settlementReason: ChallengeSettlementReason | null;
  walletPayoutChips: number;
  challengeBotTimer?: ReturnType<typeof setTimeout>;
  virtualJoinTimer?: ReturnType<typeof setTimeout>;
  virtualJoinToken: number;
  virtualJoiningPlayerId: string;
  virtualActionTimer?: ReturnType<typeof setTimeout>;
  virtualActionToken: number;
  virtualDecisionIndex: Map<string, number>;
  virtualSessionSeeds: Map<string, string>;
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

interface DisconnectGraceRecord {
  roomId: string;
  playerId: string;
  seatIndex: number;
  deadlineAtMs: number;
  token: number;
  pendingCashOutAfterHand: boolean;
  timeout?: ReturnType<typeof setTimeout>;
}

const DEFAULT_TABLE_BUY_IN = 2000;
const DEFAULT_SMALL_BLIND = 25;
const DEFAULT_BIG_BLIND = 50;
const DEFAULT_HAND_COUNT = 10;
const DEFAULT_ACTION_TIME_SECONDS = 60;
const DEFAULT_MAX_PLAYERS = 6;
const DEV_BOT_MIN_WALLET_CHIPS = 50000;
const ALLOWED_BUY_INS = new Set([1000, 2000, 5000, 10000, 20000, 50000]);
const ALLOWED_BLIND_PAIRS = new Set(["25/50", "50/100", "100/200"]);
const ALLOWED_GEM_BUY_INS = new Set([20, 50, 100, 200]);
const ALLOWED_GEM_BLIND_PAIRS = new Set(["1/2", "2/5", "5/10"]);
const ALLOWED_HAND_COUNTS = new Set([0, 5, 10, 20]);
const ALLOWED_IDENTITY_PROVIDERS = new Set(["local_dev", "steam"]);
const ACTION_TIMEOUT_MS = DEFAULT_ACTION_TIME_SECONDS * 1000;
const DISCONNECT_RECONNECT_GRACE_SECONDS = 90;
const DISCONNECT_RECONNECT_GRACE_MS = DISCONNECT_RECONNECT_GRACE_SECONDS * 1000;
const READY_COUNTDOWN_MS = 3000;
const HAND_RESULT_SHOWDOWN_MS = 5000;
const HAND_RESULT_FOLD_MS = 2500;
const TABLE_SEAT_JOIN_ORDER_9P = [5, 8, 2, 6, 4, 9, 1, 7, 3];
const PUBLIC_SEAT_JOIN_ORDER = TABLE_SEAT_JOIN_ORDER_9P;
const ROOM_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const DEV_SIMULATED_START_BLOCK_REASON = "Dev simulated player cannot play a real public hand. Use a second client or enable DEV controllable bot.";

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
  private disconnectGraceRecords = new Map<string, DisconnectGraceRecord>();
  private disconnectGraceToken = 0;
  private readonly db = getDatabase();
  private readonly players = new PlayerRepository(this.db);
  private readonly identities = new IdentityRepository(this.db);
  private readonly wallets = new WalletRepository(this.db);
  private readonly avatars = new AvatarRepository(this.db);
  private readonly loginBonus = new LoginBonusRepository(this.db, this.wallets);
  private readonly profileBootstrap = new ProfileBootstrapRepository(this.db, this.loginBonus);
  private readonly results = new ResultRepository(this.db);
  private readonly replays = new ReplayRepository(this.db);
  private readonly tableBalances = new TableBalanceRepository(this.db);
  private readonly steamPurchases = new SteamPurchaseRepository(this.db);
  private readonly steamAuthVerifier: SteamAuthVerifier;
  private readonly steamAuthMode: SteamAuthMode;
  private readonly replayIdFactory: () => string;
  private readonly steamCommerceGateway: SteamMicroTxnGateway;
  private readonly steamCommerceMode: SteamCommerceMode;
  private readonly steamCommerceConfigured: boolean;
  private readonly publicVirtualPlayers: PublicVirtualPlayerConfig;
  private readonly virtualPlayers: VirtualPlayerManager;
  private virtualSchedulerTimer?: ReturnType<typeof setInterval>;
  private readonly pendingSteamInitOrders = new Set<string>();

  constructor(options: {
    steamAuthVerifier?: SteamAuthVerifier;
    steamAuthMode?: SteamAuthMode;
    replayIdFactory?: () => string;
    steamCommerceGateway?: SteamMicroTxnGateway;
    steamCommerceMode?: SteamCommerceMode;
    steamCommerceConfigured?: boolean;
    publicVirtualPlayers?: Partial<PublicVirtualPlayerConfig>;
  } = {}) {
    this.steamAuthVerifier = options.steamAuthVerifier ?? new SteamWebApiAuthVerifier(config.steamWebApiPublisherKey);
    this.steamAuthMode = options.steamAuthMode ?? config.steamAuthMode;
    this.replayIdFactory = options.replayIdFactory ?? (() => replayIdFor());
    this.steamCommerceMode = options.steamCommerceMode ?? config.steamCommerceMode;
    this.steamCommerceGateway = options.steamCommerceGateway ?? new SteamWebApiMicroTxnGateway(this.steamCommerceMode, config.steamPublisherWebApiKey, config.steamAppId);
    this.steamCommerceConfigured = options.steamCommerceConfigured ?? (config.steamAppId !== "" && config.steamPublisherWebApiKey !== "");
    this.publicVirtualPlayers = { ...config.virtualPlayers, ...options.publicVirtualPlayers };
    this.virtualPlayers = new VirtualPlayerManager(this.publicVirtualPlayers, new VirtualPlayerRepository(this.db));
    Object.assign(this.publicVirtualPlayers, this.virtualPlayers.config());
    this.loginBonus.setProgressionRepository(this.profileBootstrap);
    this.recoverOutstandingTableBalances();
    this.recoverFinalizedSteamPurchases();
    this.startVirtualScheduler();
  }

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
      if (room.mode === "ai_challenge") {
        this.handleChallengePlayerLeave(room, client, "disconnect");
        client.ws = undefined;
        return;
      }
      if (this.shouldRefundDisconnectedBeforeOfficialHand(room, client)) {
        this.cashOut(room, client);
        this.broadcast(room);
        client.ws = undefined;
        return;
      }
      this.startDisconnectGrace(room, client);
      this.rescheduleActionTimer(room);
      this.recordHandResults(room);
      this.updatePublicRoomProgress(room);
      this.reconcilePublicVirtualPlayers(room);
      this.schedulePublicVirtualActionIfNeeded(room);
      this.broadcast(room);
    }
    client.ws = undefined;
  }

  handle(playerId: string, message: ClientMessage): void {
    const client = this.mustClient(playerId);
    if (message.type === "hello") {
      const hello = this.handleHello(client, message);
      this.recordLog(`hello ${client.id} name=${client.name}`);
      this.send(client, { type: "hello", request_id: message.request_id, player_id: client.id, server_player_id: client.id, challenge_catalog: challengeCatalog(), ...hello });
      if (hello.reconnected_to_table && hello.room_id) {
        const room = this.rooms.get(hello.room_id);
        if (room) {
          this.broadcast(room);
        }
      }
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
      const tableConfig = this.tableConfigFromMessage(message);
      this.ensureCanAffordTableConfig(client, tableConfig);
      const room = this.createRoom(tableConfig);
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
    if (message.type === "create_ai_challenge") {
      const room = this.createAiChallengeRoom(client, String(message.challenge_id || ""));
      const table = this.tableSnapshot(room);
      const existingSeat = room.table.getSeatByPlayer(client.id);
      this.send(client, {
        type: "ai_challenge_created",
        request_id: message.request_id,
        room_id: room.id,
        table,
        challenge_id: room.challengeId,
        player_seat_index: existingSeat?.seatIndex ?? 5,
        already_seated: existingSeat !== undefined,
        entry_fee_charged: room.entryFeeCharged,
        wallet: this.wallets.get(client.id),
        challenge_catalog: challengeCatalog(),
      });
      return;
    }
    if (message.type === "join_table") {
      const room = this.rooms.get(String(message.room_id || ""));
      if (!room) throw new Error("room_not_found");
      if (!room.isPublic) throw new Error("room_not_found");
      const decision = this.publicRoomListDecision(room);
      if (!decision.include) throw new Error(decision.reason === "full" ? "table_full" : "room_not_available");
      this.ensureCanAffordRoom(client, room);
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
    if (message.type === "get_wallet_history") {
      const currency = message.currency === "chips" || message.currency === "gems" ? message.currency : "all";
      const page = this.wallets.walletHistory(client.id, currency, numberOr(message.limit, 50), String(message.before || ""));
      this.send(client, {
        type: "wallet_history",
        request_id: message.request_id,
        currency,
        wallet_history: page.transactions.map(walletHistoryEntry),
        next_cursor: page.next_cursor,
      });
      return;
    }
    if (message.type === "get_store_catalog") {
      this.send(client, {
        type: "store_catalog",
        request_id: message.request_id,
        store_catalog: storeCatalog(),
        commerce_mode: this.steamCommerceMode,
        commerce_available: this.isSteamCommerceAvailable(),
      });
      return;
    }
    if (message.type === "create_store_purchase") {
      void this.createStorePurchase(client, message).catch((error) => this.sendCommerceError(client, message.request_id, error));
      return;
    }
    if (message.type === "store_purchase_authorization") {
      void this.authorizeStorePurchase(client, message).catch((error) => this.sendCommerceError(client, message.request_id, error));
      return;
    }
    if (message.type === "get_store_purchase_status") {
      this.getStorePurchaseStatus(client, message);
      return;
    }
    if (message.type === "rename_display_name") {
      const profile = this.players.renameDisplayName(client.id, String(message.display_name || ""));
      client.name = profile.display_name;
      const room = client.roomId ? this.rooms.get(client.roomId) : undefined;
      const seat = room?.table.seats.find((candidate) => candidate.playerId === client.id);
      if (room && seat) {
        seat.name = profile.display_name;
        this.broadcast(room);
      }
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
      this.send(client, {
        type: "mock_purchase_result",
        request_id: message.request_id,
        ok: true,
        player_id: client.id,
        server_player_id: client.id,
        currency,
        amount,
        source: "store_mock",
        wallet,
        wallet_chips: wallet.chips,
        profile_snapshot: this.authoritativeProfileSnapshot(client.id),
      });
      this.send(client, { type: "wallet_snapshot", request_id: message.request_id, player_id: client.id, wallet });
      return;
    }
    if (message.type === "unlock_replay") {
      this.unlockReplay(client, message);
      return;
    }
    if (message.type === "get_replay_access") {
      this.getReplayAccess(client, message);
      return;
    }
    if (message.type === "import_legacy_replay_entitlement") {
      this.importLegacyReplayEntitlement(client, message);
      return;
    }
    const roomId = message.room_id || client.roomId;
    if (!roomId) throw new Error("room_id is required");
    const room = this.mustRoom(roomId);
    switch (message.type) {
      case "join_room":
        if (room.mode === "ai_challenge") {
          if (client.id !== room.challengePlayerId) throw new Error("room_not_available");
          this.joinRoom(client, room.id);
          this.sitDownAiChallenge(room, client, 5);
          this.recordLog(`${client.id} activated AI Challenge ${room.id}`);
          break;
        }
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
      case "continue_ai_challenge":
        this.continueAiChallenge(room, client);
        this.recordLog(`${client.id} continued AI Challenge ${room.id} after hand=${room.table.handId}`);
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
    this.settleExpiredDisconnectGrace(room);
    this.clearSettledExitedSeats(room);
    this.rescheduleActionTimer(room);
    this.updatePublicRoomProgress(room);
    this.reconcilePublicVirtualPlayers(room);
    this.schedulePublicVirtualActionIfNeeded(room);
    this.scheduleChallengeBotIfNeeded(room);
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
      singleHumanWaitingSinceAt: undefined,
      localWarmupStartedAt: undefined,
      hostPlayerId: "",
      officialHandStarted: false,
      sessionComplete: false,
      mode: "public",
      challengeId: "",
      walletImpact: true,
      challengePlayerId: "",
      challengeBotPlayerId: "",
      challengeSeed: 0,
      challengeDecisionIndex: 0,
      challengeResultSent: false,
      challengeState: "creating",
      entryFeeCharged: false,
      entryFeeRefunded: false,
      settlementApplied: false,
      settlementResult: null,
      settlementReason: null,
      walletPayoutChips: 0,
      virtualJoinToken: 0,
      virtualJoiningPlayerId: "",
      virtualActionToken: 0,
      virtualDecisionIndex: new Map(),
      virtualSessionSeeds: new Map(),
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

  destroyRoom(roomId: string, reason = "room_destroyed"): boolean {
    const room = this.rooms.get(roomId);
    if (!room) return false;
    this.clearVirtualJoinTimer(room);
    if (room.virtualActionTimer) clearTimeout(room.virtualActionTimer);
    room.virtualActionTimer = undefined;
    room.virtualActionToken += 1;
    this.clearReadyCountdown(room);
    this.clearHandResultTimer(room);
    this.clearActionTimer(room);
    this.clearChallengeBotTimer(room);
    for (const seat of this.virtualPlayerSeats(room)) {
      const playerId = seat.playerId;
      room.table.leaveSeat(playerId);
      this.virtualPlayers.markOffline(playerId, reason);
    }
    for (const playerId of room.clients) {
      const client = this.clients.get(playerId);
      if (client?.roomId === roomId) client.roomId = undefined;
    }
    room.clients.clear();
    this.rooms.delete(roomId);
    this.recordLog(`room_destroyed room_id=${roomId} reason=${reason}`);
    return true;
  }

  recordLog(message: string): void {
    const timestamp = new Date().toISOString();
    this.serverLogs.push(`[${timestamp}] ${message}`);
    if (this.serverLogs.length > 120) this.serverLogs = this.serverLogs.slice(-120);
  }

  adminSnapshot(showPrivateCards: boolean): Record<string, unknown> {
    return {
      active_websocket_connections: this.activeConnectionCount(),
      human_connections: this.activeConnectionCount(),
      virtual_agents: this.virtualPlayers.onlineCount(),
      human_online: this.realOnlineCount(),
      virtual_online: this.virtualPlayers.onlineCount(),
      virtual_player_health: this.virtualPlayers.health(),
      virtual_player_recent_events: this.virtualPlayers.logs(100),
      human_active_rooms: [...this.rooms.values()].filter((room) => this.realConnectedSeatedCount(room) > 0).length,
      virtual_filled_rooms: [...this.rooms.values()].filter((room) => this.virtualPlayerSeats(room).length > 0).length,
      virtual_players: this.virtualAdminSnapshot(),
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
          virtual_player_count: this.virtualPlayerSeats(room).length,
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
            player_kind: seat.serverManagedVirtual ? "virtual" : "human",
            virtual_state: seat.serverManagedVirtual ? (seat.status === "playing" || seat.status === "all_in" ? "playing" : "seated") : undefined,
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

  setVirtualPlayersEnabled(enabled: boolean): void {
    Object.assign(this.publicVirtualPlayers, this.virtualPlayers.updateConfig({ enabled }));
    for (const room of this.rooms.values()) {
      this.reconcilePublicVirtualPlayers(room);
      this.broadcast(room);
    }
  }

  updateVirtualPlayerConfig(patch: Partial<PublicVirtualPlayerConfig>): PublicVirtualPlayerConfig {
    const updated = this.virtualPlayers.updateConfig(patch);
    Object.assign(this.publicVirtualPlayers, updated);
    this.runVirtualScheduler();
    return updated;
  }

  setVirtualProfileEnabled(playerId: string, enabled: boolean): void {
    this.virtualPlayers.setProfileEnabled(playerId, enabled);
    if (!enabled) this.requestVirtualPlayerOffline(playerId);
  }

  requestVirtualPlayerOffline(playerId: string): void {
    const entry = [...this.rooms.values()].find((room) => room.table.getSeatByPlayer(playerId)?.serverManagedVirtual);
    if (!entry) return;
    this.virtualPlayers.markPendingLeave(playerId, "admin_safe_offline");
    this.removeOneSafeVirtualPlayer(entry);
    this.broadcast(entry);
  }

  requestAllVirtualPlayersOffline(): void {
    for (const room of this.rooms.values()) {
      this.markRoomVirtualPlayersForLeave(room);
      this.removeOneSafeVirtualPlayer(room);
      this.broadcast(room);
    }
  }

  shutdown(): void {
    if (this.virtualSchedulerTimer) clearInterval(this.virtualSchedulerTimer);
    this.virtualSchedulerTimer = undefined;
    for (const room of this.rooms.values()) {
      this.clearVirtualJoinTimer(room);
      if (room.virtualActionTimer) clearTimeout(room.virtualActionTimer);
      room.virtualActionTimer = undefined;
      room.virtualActionToken += 1;
      this.clearReadyCountdown(room);
      this.clearHandResultTimer(room);
      this.clearActionTimer(room);
      this.clearChallengeBotTimer(room);
    }
    this.virtualPlayers.shutdown();
  }

  virtualPlayerHealth(): Record<string, unknown> {
    return this.virtualPlayers.health();
  }

  virtualPlayerLogs(limit = 100): Array<Record<string, unknown>> {
    return this.virtualPlayers.logs(limit);
  }

  private joinRoom(client: Client, roomId: string): void {
    const room = this.mustRoom(roomId);
    if (client.roomId && client.roomId !== roomId) {
      this.rooms.get(client.roomId)?.clients.delete(client.id);
    }
    client.roomId = roomId;
    room.clients.add(client.id);
    this.restoreDisconnectGrace(room, client);
  }

  private createPrivateTable(client: Client, message: ClientMessage): Room {
    const tableConfig = this.tableConfigFromMessage({ ...message, is_public: false });
    this.ensureCanAffordTableConfig(client, tableConfig);
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

  private createAiChallengeRoom(client: Client, challengeIdRaw: string): Room {
    if (!isChallengeId(challengeIdRaw)) throw new Error("invalid_challenge_id");
    const existing = [...this.rooms.values()].find(
      (candidate) =>
        candidate.mode === "ai_challenge" &&
        candidate.challengePlayerId === client.id &&
        candidate.challengeState !== "completed" &&
        candidate.challengeState !== "cancelled",
    );
    if (existing?.mode === "ai_challenge" && existing.challengeState !== "completed" && existing.challengeState !== "cancelled") return existing;
    const config = challengeConfigById(challengeIdRaw);
    this.wallets.ensure(client.id);
    const wallet = this.wallets.get(client.id);
    if (!wallet || wallet.chips < config.entryFeeChips) throw new Error("insufficient_chips");
    const room = this.createRoom({
      tableName: `AI Challenge: ${config.displayName}`,
      tableType: "public_chip",
      visibility: "private",
      isPublic: false,
      buyIn: config.startingStack,
      smallBlind: config.smallBlind,
      bigBlind: config.bigBlind,
      handCount: config.maxHands,
      maxPlayers: 2,
    });
    room.mode = "ai_challenge";
    room.challengeId = config.challengeId;
    room.walletImpact = config.walletImpact;
    room.challengePlayerId = client.id;
    room.challengeBotPlayerId = `challenge_bot_${room.id}`;
    room.challengeSeed = Math.floor(Math.random() * 0x7fffffff);
    room.hostPlayerId = client.id;
    room.officialHandStarted = false;
    room.challengeState = "creating";
    try {
      this.wallets.deductChips(client.id, config.entryFeeChips, { reason: "ai_challenge_entry", relatedRoomId: room.id });
      room.entryFeeCharged = true;
      room.challengeState = "ready";
    } catch (error) {
      this.refundChallengeEntryFee(room, "prestart_failure");
      this.destroyRoom(room.id, "ai_challenge_create_failed");
      throw error;
    }
    this.sendWalletSnapshot(client, room.id);
    this.recordLog(`ai_challenge_created room_id=${room.id} player_id=${client.id} challenge_id=${config.challengeId} entry_fee=${config.entryFeeChips}`);
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
    const challengeConfig = room.mode === "ai_challenge" ? challengeConfigById(room.challengeId) : undefined;
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
      mode: room.mode === "ai_challenge" ? "ai_challenge" : undefined,
      challenge_id: room.challengeId || undefined,
      difficulty: challengeConfig?.displayName,
      challenge_state: room.mode === "ai_challenge" ? room.challengeState : undefined,
      entry_fee_chips: challengeConfig?.entryFeeChips,
      timeout_win_profit_chips: challengeConfig ? challengePayout(challengeConfig, "timeout_victory").netResultChips : undefined,
      knockout_win_profit_chips: challengeConfig ? challengePayout(challengeConfig, "knockout_victory").netResultChips : undefined,
      wallet_impact: room.walletImpact,
      is_public: room.isPublic,
      created_at: room.createdAt,
      seats: this.publicSeatsWithDisconnectGrace(room),
    };
  }

  private disconnectGraceKey(roomId: string, playerId: string): string {
    return `${roomId}:${playerId}`;
  }

  private publicSeatsWithDisconnectGrace(room: Room) {
    const now = Date.now();
    return room.table.publicSnapshot().seats.map((seat) => {
      if (!seat.player_id) return seat;
      const record = this.disconnectGraceRecords.get(this.disconnectGraceKey(room.id, seat.player_id));
      if (!record) return seat;
      return {
        ...seat,
        reconnect_grace_remaining_seconds: Math.max(0, Math.ceil((record.deadlineAtMs - now) / 1000)),
      };
    });
  }

  private startDisconnectGrace(room: Room, client: Client): void {
    const seat = room.table.getSeatByPlayer(client.id);
    if (!seat) return;
    const key = this.disconnectGraceKey(room.id, client.id);
    const existing = this.disconnectGraceRecords.get(key);
    if (!existing) {
      const token = ++this.disconnectGraceToken;
      const record: DisconnectGraceRecord = {
        roomId: room.id,
        playerId: client.id,
        seatIndex: seat.seatIndex,
        deadlineAtMs: Date.now() + DISCONNECT_RECONNECT_GRACE_MS,
        token,
        pendingCashOutAfterHand: false,
      };
      record.timeout = setTimeout(() => this.handleDisconnectGraceTimeout(room.id, client.id, token), DISCONNECT_RECONNECT_GRACE_MS);
      (record.timeout as { unref?: () => void }).unref?.();
      this.disconnectGraceRecords.set(key, record);
      this.recordLog(`disconnect_grace_started room_id=${room.id} player_id=${client.id} seat=${seat.seatIndex} seconds=${DISCONNECT_RECONNECT_GRACE_SECONDS}`);
    }
    room.table.markDisconnected(client.id);
    processAutomaticTurns(room.table);
  }

  private restoreAnyDisconnectGrace(client: Client): Room | undefined {
    const record = [...this.disconnectGraceRecords.values()].find((candidate) => candidate.playerId === client.id);
    if (!record) return undefined;
    const room = this.rooms.get(record.roomId);
    if (!room) {
      this.clearDisconnectGrace(record.roomId, client.id);
      return undefined;
    }
    return this.restoreDisconnectGrace(room, client) ? room : undefined;
  }

  private restoreDisconnectGrace(room: Room, client: Client): boolean {
    const record = this.disconnectGraceRecords.get(this.disconnectGraceKey(room.id, client.id));
    if (!record) return false;
    const seat = room.table.getSeat(record.seatIndex);
    if (!seat || seat.playerId !== client.id) {
      this.clearDisconnectGrace(room.id, client.id);
      return false;
    }
    if (Date.now() > record.deadlineAtMs) {
      this.handleDisconnectGraceTimeout(room.id, client.id, record.token);
      return false;
    }
    seat.disconnected = false;
    if (seat.status === "disconnected") seat.status = seat.chips > 0 ? "sitting" : "sit_out";
    client.roomId = room.id;
    room.clients.add(client.id);
    this.clearDisconnectGrace(room.id, client.id);
    this.recordLog(`disconnect_grace_reconnected room_id=${room.id} player_id=${client.id} seat=${seat.seatIndex}`);
    return true;
  }

  private clearDisconnectGrace(roomId: string, playerId: string): void {
    const key = this.disconnectGraceKey(roomId, playerId);
    const record = this.disconnectGraceRecords.get(key);
    if (record?.timeout) clearTimeout(record.timeout);
    this.disconnectGraceRecords.delete(key);
  }

  private handleDisconnectGraceTimeout(roomId: string, playerId: string, token: number): void {
    const record = this.disconnectGraceRecords.get(this.disconnectGraceKey(roomId, playerId));
    if (!record || record.token !== token) return;
    const room = this.rooms.get(roomId);
    if (!room) {
      this.clearDisconnectGrace(roomId, playerId);
      return;
    }
    record.timeout = undefined;
    const seat = room.table.getSeat(record.seatIndex);
    if (!seat || seat.playerId !== playerId) {
      this.clearDisconnectGrace(roomId, playerId);
      return;
    }
    if (this.isCashOutDuringActiveHand(room)) {
      this.foldExpiredDisconnectedSeat(room, seat);
      this.recordHandResults(room);
      if (this.isCashOutDuringActiveHand(room)) {
        record.pendingCashOutAfterHand = true;
        this.recordLog(`disconnect_grace_expired_pending_cash_out room_id=${room.id} player_id=${playerId} seat=${seat.seatIndex}`);
        this.broadcast(room);
        return;
      }
    }
    this.cashOutExpiredDisconnectedSeat(room, playerId);
    this.broadcast(room);
  }

  private settleExpiredDisconnectGrace(room: Room): void {
    for (const record of [...this.disconnectGraceRecords.values()]) {
      if (record.roomId !== room.id) continue;
      if (Date.now() <= record.deadlineAtMs && !record.pendingCashOutAfterHand) continue;
      if (this.isCashOutDuringActiveHand(room)) continue;
      this.cashOutExpiredDisconnectedSeat(room, record.playerId);
    }
  }

  private foldExpiredDisconnectedSeat(room: Room, seat: Seat): void {
    if (seat.status !== "playing" && seat.status !== "all_in") return;
    seat.status = "folded";
    seat.ready = false;
    seat.acted = true;
    seat.lastAction = "fold";
    seat.lastActionAmount = 0;
    room.table.addAction({
      type: "player_action",
      seat_id: seat.seatIndex,
      seat_index: seat.seatIndex,
      player_name: seat.name,
      action: "fold",
      amount: 0,
      message: `${seat.name} disconnect grace expired and auto-folds.`,
    });
    if (room.table.liveSeats().length <= 1) {
      settleHand(room.table);
    } else if (room.table.currentTurnSeat === seat.seatIndex) {
      room.table.currentTurnSeat = room.table.nextActionableSeat(seat.seatIndex);
      processAutomaticTurns(room.table);
    }
  }

  private cashOutExpiredDisconnectedSeat(room: Room, playerId: string): void {
    const key = this.disconnectGraceKey(room.id, playerId);
    const record = this.disconnectGraceRecords.get(key);
    const seat = record ? room.table.getSeat(record.seatIndex) : room.table.getSeatByPlayer(playerId);
    if (!seat || seat.playerId !== playerId) {
      this.clearDisconnectGrace(room.id, playerId);
      return;
    }
    const settlementKey = `${room.id}:${playerId}`;
    if (this.settledPlayerExits.has(settlementKey)) {
      this.clearDisconnectGrace(room.id, playerId);
      return;
    }
    if (this.isCashOutDuringActiveHand(room)) {
      if (record) record.pendingCashOutAfterHand = true;
      return;
    }
    const amount = Math.max(0, Math.floor(seat.chips));
    this.settledPlayerExits.add(settlementKey);
    room.table.cashOut(playerId);
    const wallet = this.refundWalletAndClearTableBalance(playerId, room.id, roomCurrency(room), amount, "disconnected_grace_expired_cash_out", room.table.handId > 0 ? String(room.table.handId) : undefined);
    const walletAfter = roomCurrency(room) === "gems" ? wallet.gems : wallet.chips;
    const client = this.clients.get(playerId);
    if (client) {
      client.roomId = undefined;
      this.sendWalletSnapshot(client, room.id);
    }
    room.clients.delete(playerId);
    this.clearDisconnectGrace(room.id, playerId);
    this.recordLog(`disconnect_grace_expired_cash_out room_id=${room.id} player_id=${playerId} amount=${amount} wallet_after=${walletAfter}`);
  }

  private occupiedSeatCount(room: Room): number {
    return room.table.seats.filter((seat) => seat.playerId !== "").length;
  }

  private realConnectedSeatedCount(room: Room): number {
    return room.table.seats.filter((seat) => seat.playerId && !seat.isAi && !seat.warmupAi && !seat.serverManagedVirtual && !seat.disconnected).length;
  }

  private publicSeatedCount(room: Room): number {
    return room.table.seats.filter((seat) => seat.playerId !== "" && !seat.disconnected && !seat.isAi).length;
  }

  private isQuickJoinablePublicChipTable(room: Room): boolean {
    return this.publicRoomListDecision(room).include;
  }

  private handleHello(client: Client, message: ClientMessage): Omit<ServerMessage, "type" | "request_id" | "player_id"> {
    const previousId = client.id;
    const identity = this.resolveIdentity(this.steamAuthenticatedHelloMessage(message), previousId);
    const requestedId = identity.playerId;
    if (requestedId !== previousId) {
      this.clients.delete(previousId);
      client.id = requestedId;
      this.clients.set(client.id, client);
    }
    if (this.players.isBanned(client.id)) throw new Error("player_banned");
    const existingProfile = this.players.find(client.id);
    const fallbackIdentityName = identity.provider === "steam" ? existingProfile?.steam_persona_name || existingProfile?.display_name : existingProfile?.display_name;
    const displayName = String(message.player_name || message.name || fallbackIdentityName || client.name || client.id).trim() || client.id;
    const requestedAvatarId = normalizeAvatarId(String(message.avatar_id || client.avatarId || "default"));
    const isNewPlayer = !existingProfile;
    client.authProvider = identity.provider;
    client.externalId = identity.externalId;
    this.players.upsert(client.id, displayName, "default", identity.provider);
    this.wallets.ensure(client.id);
    this.identities.linkIdentity(client.id, identity.provider, identity.externalId);
    this.avatars.unlockAvatar(client.id, "default");
    this.profileBootstrap.bootstrapPlayer(client.id);
    const avatarId = this.avatars.hasAvatar(client.id, requestedAvatarId) ? requestedAvatarId : "default";
    const profile = this.players.upsert(client.id, displayName, avatarId, identity.provider);
    const dailyStatus = this.loginBonus.status(client.id);
    this.ensureDevBotWallet(client.id);
    const reconnectedRoom = this.restoreAnyDisconnectGrace(client);
    const wallet = this.wallets.get(client.id)!;
    const unlocked = this.avatars.getUnlockedAvatars(client.id);
    client.name = profile.display_name;
    client.avatarId = profile.avatar_id;
    return {
      server_player_id: client.id,
      room_id: reconnectedRoom?.id,
      reconnected_to_table: Boolean(reconnectedRoom),
      profile,
      wallet,
      unlocked_avatar_ids: unlocked,
      daily_bonus_status: dailyStatus,
      is_new_player: isNewPlayer,
      profile_snapshot: this.authoritativeProfileSnapshot(client.id, isNewPlayer),
      warning: avatarId !== requestedAvatarId ? `avatar ${requestedAvatarId} is not unlocked; using default` : undefined,
    };
  }

  private profilePayload(playerId: string): Pick<ServerMessage, "profile" | "profile_snapshot" | "wallet" | "unlocked_avatar_ids" | "daily_bonus_status"> {
    const profile = this.players.find(playerId);
    const wallet = this.wallets.get(playerId);
    return {
      profile,
      wallet,
      unlocked_avatar_ids: this.avatars.getUnlockedAvatars(playerId),
      daily_bonus_status: this.loginBonus.status(playerId),
      profile_snapshot: this.authoritativeProfileSnapshot(playerId),
    };
  }

  private authoritativeProfileSnapshot(playerId: string, isNewPlayer = false) {
    const client = this.clients.get(playerId);
    return {
      ...this.profileBootstrap.getProfileSnapshot(playerId, isNewPlayer),
      replay_economy: REPLAY_ECONOMY_CONFIG,
      challenge_catalog: challengeCatalog(),
      mock_purchase_allowed: client ? this.canUseMockPurchase(client) : false,
    };
  }

  private isSteamCommerceAvailable(): boolean {
    if (this.steamCommerceMode === "disabled" || !this.steamCommerceConfigured) return false;
    if (this.steamCommerceMode === "production" && this.steamAuthMode !== "required") return false;
    return true;
  }

  private async createStorePurchase(client: Client, message: ClientMessage): Promise<void> {
    this.requireSteamCommerceIdentity(client);
    if (!this.isSteamCommerceAvailable()) throw new Error("steam_commerce_unavailable");
    const packageId = String(message.package_id || "").trim();
    const item = findStorePackage(packageId);
    if (!item) throw new Error("store_package_not_found");
    if (!item.enabled) throw new Error("store_package_disabled");
    const idempotencyKey = normalizePurchaseIdempotencyKey(String(message.idempotency_key || message.request_id || ""));
    const order = this.steamPurchases.createOrder(
      client.id,
      String(client.externalId),
      item,
      this.steamCommerceMode as Exclude<SteamCommerceMode, "disabled">,
      idempotencyKey,
    );
    if (order.status !== "created" || this.pendingSteamInitOrders.has(order.order_id)) {
      this.sendPurchaseState(client, "store_purchase_created", order, message.request_id);
      return;
    }
    this.pendingSteamInitOrders.add(order.order_id);
    try {
      const result = await this.steamCommerceGateway.initTxn(order);
      if (!result.ok) {
        const failed = this.steamPurchases.markFailed(order.order_id, result.error_code || "steam_purchase_init_failed", result.error_message || "Steam InitTxn failed.");
        this.sendPurchaseState(client, "store_purchase_result", failed, message.request_id);
        return;
      }
      const initialized = this.steamPurchases.markInitialized(order.order_id, result.steam_trans_id || "");
      this.recordLog(`steam_purchase_initialized player_id=${client.id} order_id=${initialized.order_id} package_id=${initialized.package_id} environment=${initialized.environment}`);
      this.sendPurchaseState(client, "store_purchase_created", initialized, message.request_id);
    } finally {
      this.pendingSteamInitOrders.delete(order.order_id);
    }
  }

  private async authorizeStorePurchase(client: Client, message: ClientMessage): Promise<void> {
    this.requireSteamCommerceIdentity(client);
    const orderId = String(message.order_id || "").trim();
    let order = this.steamPurchases.getForPlayer(orderId, client.id);
    if (!order) throw new Error("steam_purchase_not_found");
    if (String(order.steam_id) !== String(client.externalId)) throw new Error("steam_purchase_access_denied");
    if (order.status === "granted" || order.status === "cancelled" || order.status === "failed" || order.status === "refunded") {
      this.sendPurchaseState(client, "store_purchase_result", order, message.request_id);
      return;
    }
    if (!boolOrFalse(message.authorized)) {
      order = this.steamPurchases.markCancelled(order.order_id);
      this.recordLog(`steam_purchase_cancelled player_id=${client.id} order_id=${order.order_id}`);
      this.sendPurchaseState(client, "store_purchase_result", order, message.request_id);
      return;
    }
    if (!this.isSteamCommerceAvailable()) throw new Error("steam_commerce_unavailable");
    if (order.status === "initialized") order = this.steamPurchases.markAuthorized(order.order_id);
    if (order.status === "finalized") {
      const grant = this.steamPurchases.grantFinalizedOrder(order.order_id);
      this.sendPurchaseGrant(client, grant.order, message.request_id, grant.already_granted);
      return;
    }
    const finalizing = this.steamPurchases.beginFinalizing(order.order_id);
    if (!finalizing.acquired) {
      this.sendPurchaseState(client, "store_purchase_result", finalizing.order, message.request_id);
      return;
    }
    const result = await this.steamCommerceGateway.finalizeTxn(finalizing.order);
    if (!result.ok) {
      const failed = this.steamPurchases.markFailed(order.order_id, result.error_code || "steam_purchase_finalize_failed", result.error_message || "Steam FinalizeTxn failed.");
      this.sendPurchaseState(client, "store_purchase_result", failed, message.request_id);
      return;
    }
    const finalized = this.steamPurchases.markFinalized(order.order_id, result.steam_trans_id || "");
    const grant = this.steamPurchases.grantFinalizedOrder(finalized.order_id);
    this.recordLog(`steam_purchase_granted player_id=${client.id} order_id=${grant.order.order_id} package_id=${grant.order.package_id}`);
    this.sendPurchaseGrant(client, grant.order, message.request_id, grant.already_granted);
  }

  private getStorePurchaseStatus(client: Client, message: ClientMessage): void {
    this.requireSteamCommerceIdentity(client);
    const orderId = String(message.order_id || "").trim();
    if (orderId === "") {
      this.send(client, {
        type: "store_purchase_result",
        request_id: message.request_id,
        orders: this.steamPurchases.recentForPlayer(client.id).map((order) => this.storePurchaseOrderSnapshot(order)),
        commerce_mode: this.steamCommerceMode,
        commerce_available: this.isSteamCommerceAvailable(),
      });
      return;
    }
    let order = this.steamPurchases.getForPlayer(orderId, client.id);
    if (!order) throw new Error("steam_purchase_not_found");
    if (order.status === "finalized") order = this.steamPurchases.grantFinalizedOrder(order.order_id).order;
    this.sendPurchaseState(client, "store_purchase_result", order, message.request_id);
  }

  private sendPurchaseGrant(client: Client, order: SteamPurchaseOrderRecord, requestId?: string, alreadyGranted = false): void {
    const wallet = this.wallets.get(client.id);
    this.send(client, {
      type: "store_purchase_result",
      request_id: requestId,
      ok: true,
      order: this.storePurchaseOrderSnapshot(order),
      wallet,
      profile_snapshot: this.authoritativeProfileSnapshot(client.id),
      reason: alreadyGranted ? "already_granted" : "purchase_completed",
    });
    if (wallet) this.send(client, { type: "wallet_snapshot", player_id: client.id, wallet });
  }

  private sendPurchaseState(client: Client, type: "store_purchase_created" | "store_purchase_result", order: SteamPurchaseOrderRecord, requestId?: string): void {
    this.send(client, {
      type,
      request_id: requestId,
      ok: order.status === "initialized" || order.status === "authorized" || order.status === "finalizing" || order.status === "finalized" || order.status === "granted",
      order: this.storePurchaseOrderSnapshot(order),
      commerce_mode: this.steamCommerceMode,
      commerce_available: this.isSteamCommerceAvailable(),
    });
  }

  private storePurchaseOrderSnapshot(order: SteamPurchaseOrderRecord) {
    return {
      order_id: order.order_id,
      package_id: order.package_id,
      package_title: order.package_title,
      chips_amount: order.chips_amount,
      gems_amount: order.gems_amount,
      price_minor: order.price_minor,
      price_currency: order.price_currency,
      environment: order.environment,
      status: order.status,
      created_at: order.created_at,
      initialized_at: order.initialized_at,
      authorized_at: order.authorized_at,
      finalized_at: order.finalized_at,
      granted_at: order.granted_at,
      cancelled_at: order.cancelled_at,
      failed_at: order.failed_at,
      failure_code: order.failure_code,
    };
  }

  private requireSteamCommerceIdentity(client: Client): void {
    if (client.authProvider !== "steam" || !/^\d{15,20}$/.test(String(client.externalId || ""))) throw new Error("steam_purchase_invalid_identity");
  }

  private sendCommerceError(client: Client, requestId: string | undefined, error: unknown): void {
    const code = error instanceof Error ? error.message : String(error);
    this.recordLog(`steam_purchase_error player_id=${client.id} code=${code}`);
    this.send(client, { type: "error", request_id: requestId, error: code, error_code: code });
  }

  private recoverFinalizedSteamPurchases(): void {
    try {
      const recovered = this.steamPurchases.recoverFinalizedOrders();
      for (const result of recovered) this.recordLog(`steam_purchase_recovery order_id=${result.order.order_id} player_id=${result.order.player_id}`);
    } catch (error) {
      const code = error instanceof Error ? error.message : String(error);
      this.recordLog(`steam_purchase_recovery_failed code=${code}`);
    }
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
      const requestedType = String(message.replay_type || "").trim();
      let replay = this.replays.getReplayIndex(replayId);
      if (!replay) {
        if (requestedType !== "ai" && requestedType !== "training") throw new Error("replay_not_found");
        replay = this.replays.ensureLocalReplay(replayId, client.id, requestedType);
      }
      const replayType = String(replay.replay_type || "official_human");
      if (!isReplayType(replayType)) throw new Error("invalid_replay_type");
      if (requestedType !== "" && (!isReplayType(requestedType) || requestedType !== replayType)) throw new Error("invalid_replay_type");
      if (!this.replays.isParticipant(replayId, client.id)) throw new Error("replay_access_denied");
      const requiresKey = replayType === "official_human" || replayType === "room_replay";
      const key = this.replays.getReplayKey(replayId);
      if (requiresKey && !key) throw new Error("replay_key_missing");
      if (requiresKey) this.validateReplayClientIdentity(message, replay, key?.key_version ?? 0);
      const priceGems = replayUnlockCost(replayType);
      const existing = this.replays.getUnlock(replayId, client.id);
      if (existing) {
        return {
          replay,
          key,
          replayType,
          priceGems,
          wallet: this.wallets.get(client.id) ?? this.wallets.ensure(client.id),
          alreadyUnlocked: true,
        };
      }
      const wallet = this.wallets.get(client.id) ?? this.wallets.ensure(client.id);
      if (wallet.gems < priceGems) throw new Error("insufficient_gems");
      const updatedWallet = this.wallets.deductGems(client.id, priceGems, {
        reason: replayUnlockReason(replayType),
        relatedRoomId: replay.room_id,
        relatedHandId: replay.hand_id,
      });
      this.replays.recordUnlock(replayId, client.id, priceGems, "gems");
      return { replay, key, replayType, priceGems, wallet: updatedWallet, alreadyUnlocked: false };
    })();
    this.send(client, {
      type: "replay_unlocked",
      request_id: message.request_id,
      player_id: client.id,
      server_player_id: client.id,
      replay_id: replayId,
      replay_key: result.key?.key_material,
      key_version: result.key?.key_version,
      checksum: result.replay.checksum,
      algorithm: result.replay.algorithm || REPLAY_ENCRYPTION_ALGORITHM,
      already_unlocked: result.alreadyUnlocked,
      replay_type: result.replayType,
      price_gems: result.priceGems,
      wallet: result.wallet,
      profile_snapshot: this.authoritativeProfileSnapshot(client.id),
    });
    this.send(client, { type: "wallet_snapshot", request_id: message.request_id, player_id: client.id, wallet: result.wallet });
  }

  private getReplayAccess(client: Client, message: ClientMessage): void {
    const replayId = String(message.replay_id || "").trim();
    if (replayId === "") throw new Error("replay_not_found");
    const requestedType = String(message.replay_type || "").trim();
    let replay = this.replays.getReplayIndex(replayId);
    if (!replay && (requestedType === "ai" || requestedType === "training")) {
      replay = this.replays.ensureLocalReplay(replayId, client.id, requestedType);
    }
    if (!replay) {
      this.send(client, {
        type: "replay_access",
        request_id: message.request_id,
        replay_id: replayId,
        replay_type: isReplayType(requestedType) ? requestedType : "official_human",
        participant: false,
        unlocked: false,
        price_gems: isReplayType(requestedType) ? replayUnlockCost(requestedType) : replayUnlockCost("official_human"),
        supported: false,
        legacy_reason: "replay_not_found",
        access_denied_reason: "replay_not_found",
      });
      return;
    }
    const participant = this.replays.isParticipant(replayId, client.id);
    const replayType = String(replay.replay_type || "official_human");
    if (!isReplayType(replayType)) throw new Error("invalid_replay_type");
    const key = this.replays.getReplayKey(replayId);
    const requiresKey = replayType === "official_human" || replayType === "room_replay";
    let supported = replay.integrity_status !== "collision" && replay.integrity_status !== "corrupted";
    let legacyReason = supported ? "" : replay.integrity_status;
    const requestedChecksum = String(message.checksum || "").trim();
    if (requiresKey && requestedChecksum !== replay.checksum) {
      supported = false;
      legacyReason = requestedChecksum === "" ? "missing_checksum" : "checksum_mismatch";
    }
    const requestedKeyVersion = Number(message.key_version || 0);
    if (requiresKey && (!key || requestedKeyVersion !== key.key_version)) {
      supported = false;
      legacyReason = !key ? "replay_key_missing" : "key_version_mismatch";
    }
    const requestedAlgorithm = String(message.algorithm || "").trim();
    const algorithm = replay.algorithm || REPLAY_ENCRYPTION_ALGORITHM;
    if (requiresKey && requestedAlgorithm !== algorithm) {
      supported = false;
      legacyReason = requestedAlgorithm === "" ? "missing_algorithm" : "algorithm_mismatch";
    }
    this.send(client, {
      type: "replay_access",
      request_id: message.request_id,
      replay_id: replayId,
      replay_type: replayType,
      checksum: replay.checksum,
      key_version: key?.key_version ?? 0,
      participant,
      unlocked: participant && supported && this.replays.isUnlocked(replayId, client.id),
      price_gems: replayUnlockCost(replayType),
      supported: participant && supported,
      legacy_reason: legacyReason,
      access_denied_reason: participant ? "" : "not_participant",
      algorithm,
      storage_mode: requiresKey ? "official_encrypted" : "local_only_plaintext",
      integrity_status: replay.integrity_status,
    });
  }

  private importLegacyReplayEntitlement(client: Client, message: ClientMessage): void {
    if (!this.canImportLegacyReplay(client)) throw new Error("legacy_replay_import_disabled");
    const replayId = String(message.replay_id || "").trim();
    if (replayId === "") throw new Error("replay_not_found");
    const replay = this.replays.getReplayIndex(replayId);
    if (!replay) throw new Error("replay_not_found");
    if (!this.replays.isParticipant(replayId, client.id)) throw new Error("replay_access_denied");
    const key = this.replays.getReplayKey(replayId);
    if (!key) throw new Error("replay_key_missing");
    const replayType = String(replay.replay_type || "official_human");
    if (!isReplayType(replayType)) throw new Error("invalid_replay_type");
    this.validateReplayClientIdentity(message, replay, key.key_version);
    this.replays.recordUnlock(replayId, client.id, 0, "gems", "legacy_replay_entitlement_import");
    this.recordLog(`legacy_replay_entitlement_import player_id=${client.id} replay_id=${replayId}`);
    this.send(client, {
      type: "replay_access",
      request_id: message.request_id,
      replay_id: replayId,
      replay_type: replayType,
      checksum: replay.checksum,
      key_version: key?.key_version ?? 0,
      participant: true,
      unlocked: true,
      price_gems: replayUnlockCost(replayType),
      supported: true,
      legacy_reason: "",
      access_denied_reason: "",
      algorithm: replay.algorithm || REPLAY_ENCRYPTION_ALGORITHM,
      storage_mode: "official_encrypted",
      integrity_status: replay.integrity_status,
    });
  }

  private validateReplayClientIdentity(message: ClientMessage, replay: ReplayIndexRecord, keyVersion: number): void {
    if (String(message.checksum || "").trim() !== replay.checksum) throw new Error("replay_checksum_mismatch");
    if (Number(message.key_version || 0) !== keyVersion) throw new Error("replay_key_version_mismatch");
    const algorithm = replay.algorithm || REPLAY_ENCRYPTION_ALGORITHM;
    if (String(message.algorithm || "").trim() !== algorithm) throw new Error("replay_unsupported");
    if (String(message.storage_mode || "").trim() !== "official_encrypted") throw new Error("replay_unsupported");
    if (replay.integrity_status === "collision" || replay.integrity_status === "corrupted") throw new Error("replay_unsupported");
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
    room.localWarmupStartedAt ??= new Date().toISOString();
    room.isAiWarmup = false;
    room.table.addAction({ type: "system", action: "local_warmup", message: `${client.name} started local AI warm-up. Public room remains open for real players.` });
  }

  private mockPurchase(client: Client, currency: "chips" | "gems", amount: number) {
    if (!this.canUseMockPurchase(client)) throw new Error(config.allowMockPurchases ? "mock_purchase_not_allowed" : "mock_purchase_disabled");
    const normalized = Math.floor(amount);
    if (normalized <= 0) throw new Error("invalid_amount");
    this.wallets.ensure(client.id);
    if (currency === "gems") {
      return this.wallets.addGems(client.id, normalized, { reason: "store_mock_purchase" });
    }
    return this.wallets.addChips(client.id, normalized, { reason: "store_mock_purchase" });
  }

  private canUseMockPurchase(client: Client): boolean {
    if (config.nodeEnv === "production") return false;
    if (!config.allowMockPurchases) return false;
    if (client.authProvider === "local_dev") return true;
    if (client.authProvider !== "steam") return false;
    const steamId = String(client.externalId || "");
    return steamId !== "" && config.mockPurchaseAllowedSteamIds.includes(steamId);
  }

  private canImportLegacyReplay(client: Client): boolean {
    if (client.authProvider !== "steam") return false;
    const steamId = String(client.externalId || "");
    return steamId !== "" && config.legacyReplayImportAllowedSteamIds.includes(steamId);
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
    this.ensureRoomCanAcceptSitDown(room);
    if (room.mode === "ai_challenge") return this.sitDownAiChallenge(room, client, requestedSeatIndex);
    if (this.occupiedSeatCount(room) >= room.maxPlayers) throw new Error("table_full");
    const seat = requestedSeatIndex < 0 ? this.firstAvailablePublicSeat(room) : room.table.getSeat(requestedSeatIndex);
    if (!seat || seat.playerId) throw new Error("seat is not available");
    const seatIndex = seat.seatIndex;
    this.wallets.ensure(client.id);
    const wallet = this.wallets.get(client.id);
    const currency = roomCurrency(room);
    const walletBalance = currency === "gems" ? (wallet?.gems ?? 0) : (wallet?.chips ?? 0);
    if (!wallet || walletBalance < room.buyIn) throw new Error(currency === "gems" ? "insufficient_gems" : "insufficient_chips");
    this.deductWalletToTableBalance(client.id, room.id, currency, room.buyIn);
    try {
      if (room.hostPlayerId === "") room.hostPlayerId = client.id;
      room.table.sitDown(toPlayer(client), seatIndex, room.buyIn);
      if (room.hostInLocalWarmup !== "" && this.realConnectedSeatedCount(room) >= 2) {
        const hostId = room.hostInLocalWarmup;
        room.hostInLocalWarmup = "";
        room.table.addAction({ type: "system", action: "real_player_joined", message: "Real player joined. Return from local AI warm-up to public table." });
        this.recordLog(`real_player_joined_interrupts_local_warmup room_id=${room.id} host_player_id=${hostId} joined_player_id=${client.id}`);
      }
    } catch (error) {
      this.refundOutstandingTableBalance(client.id, room.id, "refunded_sit_down_failed");
      throw error;
    }
    const occupiedCount = this.occupiedSeatCount(room);
    const acceptedSeat = room.table.getSeat(seatIndex);
    this.recordLog(
      `sit_down accepted room_id=${room.id} connection_player_id=${client.id} payload_player_id=${payloadPlayerId || "-"} requested_seat_index=${requestedSeatIndex} seat_index=${seatIndex} seat_player_id=${acceptedSeat?.playerId || "-"} occupied_count=${occupiedCount}`,
    );
    this.sendWalletSnapshot(client, room.id);
    return seatIndex;
  }

  private sitDownAiChallenge(room: Room, client: Client, requestedSeatIndex: number): number {
    if (client.id !== room.challengePlayerId) throw new Error("room_not_available");
    const existingSeat = room.table.getSeatByPlayer(client.id);
    if (existingSeat) {
      this.startChallengeHandIfNeeded(room, "challenge_join_idempotent");
      return existingSeat.seatIndex;
    }
    const config = challengeConfigById(room.challengeId);
    const playerSeatIndex = requestedSeatIndex >= 0 ? requestedSeatIndex : 5;
    const playerSeat = room.table.getSeat(playerSeatIndex);
    if (!playerSeat || playerSeat.playerId) throw new Error("seat is not available");
    room.table.sitDown(toPlayer(client), playerSeatIndex, config.startingStack);
    room.table.setReady(client.id, true);
    const botSeatIndex = playerSeatIndex === 5 ? 8 : 5;
    room.table.sitDown({
      id: room.challengeBotPlayerId,
      name: `${config.displayName} Rule Bot`,
      connected: true,
      avatarId: "default",
      isAi: true,
    }, botSeatIndex, config.startingStack);
    room.table.setReady(room.challengeBotPlayerId, true);
    room.table.addAction({ type: "system", action: "ai_challenge", message: `${config.displayName} AI Challenge started. Entry fee paid from wallet; event stacks are table-only.` });
    this.startChallengeHandIfNeeded(room, "challenge_sit_down");
    return playerSeatIndex;
  }

  private ensureRoomCanAcceptSitDown(room: Room): void {
    if (room.sessionComplete || room.table.phase === "session_complete") throw new Error("room_not_available");
    if (room.table.phase === "hand_over" && room.officialHandStarted) throw new Error("room_not_available");
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
    return room.table.seats.filter((seat) => seat.playerId && (!seat.isAi || seat.serverManagedVirtual) && !seat.warmupAi && !seat.disconnected && seat.chips > 0 && !["empty", "sit_out"].includes(seat.status));
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
    if (room.mode === "ai_challenge") {
      this.updateChallengeProgress(room);
      return;
    }
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
    this.schedulePublicVirtualActionIfNeeded(room);
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
    this.settleExpiredDisconnectGrace(room);
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
    this.reconcilePublicVirtualPlayers(room);
    this.schedulePublicVirtualActionIfNeeded(room);
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

  private updateChallengeProgress(room: Room): void {
    if (room.sessionComplete) return;
    if (room.table.phase === "hand_over") {
      if (this.challengeShouldEnd(room)) this.completeChallengeSession(room);
      else {
        room.challengeState = "hand_result";
        this.clearActionTimer(room);
        this.clearChallengeBotTimer(room);
      }
      return;
    }
    if (room.table.phase === "waiting" && this.challengeSeatsReady(room)) {
      this.startChallengeHandIfNeeded(room, "challenge_waiting_start");
    }
  }

  private startChallengeHandIfNeeded(room: Room, reason: string): void {
    if (room.mode !== "ai_challenge" || room.sessionComplete || !this.challengeSeatsReady(room)) return;
    if (!["waiting", "hand_over"].includes(room.table.phase)) return;
    if (this.challengeShouldEnd(room)) {
      this.completeChallengeSession(room);
      return;
    }
    room.table.startHand(Date.now(), false);
    room.officialHandStarted = true;
    room.challengeState = "started";
    this.recordLog(`ai_challenge_hand_started room_id=${room.id} reason=${reason} hand_id=${room.table.handId}`);
    this.scheduleChallengeBotIfNeeded(room);
  }

  private continueAiChallenge(room: Room, client: Client): void {
    if (room.mode !== "ai_challenge" || client.id !== room.challengePlayerId) throw new Error("room_not_available");
    if (room.sessionComplete || room.table.phase === "session_complete") throw new Error("session_complete");
    if (room.table.phase !== "hand_over" || room.challengeState !== "hand_result") throw new Error("not_waiting");
    this.startChallengeHandIfNeeded(room, "challenge_player_continue");
  }

  private challengeSeatsReady(room: Room): boolean {
    const player = room.table.getSeatByPlayer(room.challengePlayerId);
    const bot = room.table.getSeatByPlayer(room.challengeBotPlayerId);
    return Boolean(player && bot && !player.disconnected && !bot.disconnected);
  }

  private challengeShouldEnd(room: Room): boolean {
    const player = room.table.getSeatByPlayer(room.challengePlayerId);
    const bot = room.table.getSeatByPlayer(room.challengeBotPlayerId);
    if (!player || !bot) return true;
    if (player.chips <= 0 || bot.chips <= 0) return true;
    return room.table.phase === "hand_over" && room.table.handId >= challengeConfigById(room.challengeId).maxHands;
  }

  private completeChallengeSession(room: Room): void {
    if (room.sessionComplete) return;
    room.sessionComplete = true;
    room.challengeState = "completed";
    room.table.phase = "session_complete";
    room.table.currentTurnSeat = -1;
    this.clearActionTimer(room);
    this.clearChallengeBotTimer(room);
    this.applyChallengeSettlement(room, this.challengeSettlementResult(room));
    const payload = this.challengeResultPayload(room);
    room.table.addAction({ type: "system", action: "ai_challenge_result", message: `AI Challenge complete: ${payload.display_result}. ${payload.settlement_reason_text}` });
    this.recordLog(`ai_challenge_complete room_id=${room.id} result=${payload.settlement_result} payout=${payload.wallet_payout_chips} player_stack=${payload.player_final_stack} bot_stack=${payload.bot_final_stack} hands=${payload.hands_played}`);
    this.sendChallengeResult(room);
  }

  private restartPublicSession(room: Room, client: Client): void {
    if (room.mode === "ai_challenge") {
      if (client.id !== room.challengePlayerId) throw new Error("not_seated");
      this.restartChallengeSession(room);
      return;
    }
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

  private restartChallengeSession(room: Room): void {
    const config = challengeConfigById(room.challengeId);
    const client = this.clients.get(room.challengePlayerId);
    if (!client) throw new Error("not_seated");
    this.wallets.ensure(client.id);
    const wallet = this.wallets.get(client.id);
    if (!wallet || wallet.chips < config.entryFeeChips) throw new Error("insufficient_chips");
    this.wallets.deductChips(client.id, config.entryFeeChips, { reason: "ai_challenge_entry", relatedRoomId: room.id });
    room.sessionComplete = false;
    room.officialHandStarted = false;
    room.challengeState = "ready";
    room.challengeDecisionIndex = 0;
    room.challengeResultSent = false;
    room.entryFeeCharged = true;
    room.entryFeeRefunded = false;
    room.settlementApplied = false;
    room.settlementResult = null;
    room.settlementReason = null;
    room.walletPayoutChips = 0;
    this.clearChallengeBotTimer(room);
    room.table.resetForNewSession();
    for (const seat of room.table.seats) {
      if (seat.playerId === room.challengePlayerId || seat.playerId === room.challengeBotPlayerId) {
        seat.chips = config.startingStack;
        seat.ready = true;
        seat.status = "ready";
      }
    }
    this.sendWalletSnapshot(client, room.id);
    this.startChallengeHandIfNeeded(room, "challenge_restart");
  }

  private handleChallengePlayerLeave(room: Room, client: Client, source: "cash_out" | "disconnect"): void {
    if (client.id !== room.challengePlayerId) return;
    this.clearChallengeBotTimer(room);
    if (room.challengeState === "creating" || room.challengeState === "ready" || !room.officialHandStarted || room.table.handId <= 0) {
      this.refundChallengeEntryFee(room, "prestart_failure");
      room.challengeState = "cancelled";
      room.sessionComplete = true;
      room.table.phase = "session_complete";
    } else if (!room.sessionComplete) {
      this.applyChallengeSettlement(room, { result: "defeat", reason: "player_left" });
      room.challengeState = "completed";
      room.sessionComplete = true;
      room.table.phase = "session_complete";
      room.table.currentTurnSeat = -1;
      this.sendChallengeResult(room);
    }
    room.table.leaveSeat(client.id);
    room.clients.delete(client.id);
    client.roomId = undefined;
    this.sendWalletSnapshot(client, room.id);
    this.recordLog(`ai_challenge_${source}_cleanup room_id=${room.id} player_id=${client.id} state=${room.challengeState}`);
  }

  private refundChallengeEntryFee(room: Room, reason: ChallengeSettlementReason): void {
    if (!room.entryFeeCharged || room.entryFeeRefunded) return;
    const config = challengeConfigById(room.challengeId);
    this.wallets.addChips(room.challengePlayerId, config.entryFeeChips, { reason: "ai_challenge_entry_refund", relatedRoomId: room.id });
    room.entryFeeRefunded = true;
    room.settlementApplied = true;
    room.settlementResult = "prestart_cancelled";
    room.settlementReason = reason;
    room.walletPayoutChips = config.entryFeeChips;
  }

  private challengeSettlementResult(room: Room): { result: ChallengeSettlementResult; reason: ChallengeSettlementReason } {
    const player = room.table.getSeatByPlayer(room.challengePlayerId);
    const bot = room.table.getSeatByPlayer(room.challengeBotPlayerId);
    const playerStack = Math.max(0, Math.floor(player?.chips ?? 0));
    const botStack = Math.max(0, Math.floor(bot?.chips ?? 0));
    if (playerStack <= 0) return { result: "defeat", reason: "player_eliminated" };
    if (botStack <= 0) return { result: "knockout_victory", reason: "bot_eliminated" };
    if (playerStack > botStack) return { result: "timeout_victory", reason: "player_ahead_at_hand_limit" };
    if (playerStack < botStack) return { result: "defeat", reason: "bot_ahead_at_hand_limit" };
    return { result: "draw", reason: "equal_stacks_at_hand_limit" };
  }

  private applyChallengeSettlement(room: Room, settlement: { result: ChallengeSettlementResult; reason: ChallengeSettlementReason }): void {
    if (room.settlementApplied) return;
    const config = challengeConfigById(room.challengeId);
    const payout = challengePayout(config, settlement.result);
    if (payout.walletPayoutChips > 0) {
      this.wallets.addChips(room.challengePlayerId, payout.walletPayoutChips, { reason: "ai_challenge_reward", relatedRoomId: room.id, relatedHandId: String(room.table.handId) });
    }
    room.settlementApplied = true;
    room.settlementResult = settlement.result;
    room.settlementReason = settlement.reason;
    room.walletPayoutChips = payout.walletPayoutChips;
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
    if (room.mode === "ai_challenge") throw new Error("cannot_add_chips_during_hand");
    const normalized = Math.floor(amount);
    if (normalized <= 0) throw new Error("invalid_amount");
    const seat = room.table.getSeatByPlayer(client.id);
    if (!seat) throw new Error("not_seated");
    if (!room.table.canMoveTableChips()) throw new Error("cannot_add_chips_during_hand");
    this.wallets.ensure(client.id);
    const wallet = this.wallets.get(client.id);
    if (!wallet || wallet.chips < normalized) throw new Error("insufficient_chips");
    this.deductWalletToTableBalance(client.id, room.id, "chips", normalized, "add_table_chips");
    try {
      room.table.addTableChips(client.id, normalized);
    } catch (error) {
      this.refundWalletAndReduceTableBalance(client.id, room.id, "chips", normalized, "refunded_add_table_chips_failed");
      throw error;
    }
    this.sendWalletSnapshot(client, room.id);
  }

  private cashOut(room: Room, client: Client): void {
    if (room.mode === "ai_challenge") {
      this.handleChallengePlayerLeave(room, client, "cash_out");
      return;
    }
    const seat = room.table.getSeatByPlayer(client.id);
    const settlementKey = `${room.id}:${client.id}`;
    this.clearDisconnectGrace(room.id, client.id);
    if (!seat) {
      const recovered = this.refundOutstandingTableBalance(client.id, room.id, this.exitSettlementReason(room));
      if (recovered > 0) {
        this.settledPlayerExits.add(settlementKey);
        this.sendWalletSnapshot(client, room.id);
        return;
      }
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
    const wallet = this.refundWalletAndClearTableBalance(client.id, room.id, roomCurrency(room), amount, reason, room.table.handId > 0 ? String(room.table.handId) : undefined);
    const walletAfter = roomCurrency(room) === "gems" ? wallet.gems : wallet.chips;
    this.recordLog(`Wallet refund: currency=${roomCurrency(room)} reason=${reason} player_id=${client.id} amount=${amount} wallet_after=${walletAfter} room_id=${room.id}`);
    this.sendWalletSnapshot(client, room.id);
    room.clients.delete(client.id);
    client.roomId = undefined;
  }

  private deductWalletToTableBalance(playerId: string, roomId: string, currency: RoomCurrency, amount: number, chipReason = "table_buy_in"): void {
    const normalized = Math.max(0, Math.floor(amount));
    const transaction = this.db.transaction(() => {
      if (currency === "gems") this.wallets.deductGems(playerId, normalized, { reason: chipReason === "add_table_chips" ? "add_table_chips" : "gem_table_buy_in", relatedRoomId: roomId });
      else this.wallets.deductChips(playerId, normalized, { reason: chipReason, relatedRoomId: roomId });
      this.tableBalances.add(roomId, playerId, currency as TableBalanceCurrency, normalized);
    });
    transaction();
  }

  private refundWalletAndClearTableBalance(playerId: string, roomId: string, currency: RoomCurrency, amount: number, reason: string, handId?: string) {
    const normalized = Math.max(0, Math.floor(amount));
    const transaction = this.db.transaction(() => {
      const wallet = currency === "gems"
        ? this.wallets.addGems(playerId, normalized, { reason, relatedRoomId: roomId, relatedHandId: handId })
        : this.wallets.refundTableChips(playerId, normalized, { reason, relatedRoomId: roomId, relatedHandId: handId });
      this.tableBalances.clear(roomId, playerId);
      return wallet;
    });
    return transaction();
  }

  private refundWalletAndReduceTableBalance(playerId: string, roomId: string, currency: RoomCurrency, amount: number, reason: string): void {
    const normalized = Math.max(0, Math.floor(amount));
    if (normalized <= 0) return;
    const transaction = this.db.transaction(() => {
      if (currency === "gems") this.wallets.addGems(playerId, normalized, { reason, relatedRoomId: roomId });
      else this.wallets.refundTableChips(playerId, normalized, { reason, relatedRoomId: roomId });
      const balance = this.tableBalances.get(roomId, playerId);
      if (!balance) return;
      this.tableBalances.set(roomId, playerId, balance.currency, Math.max(0, balance.amount - normalized));
    });
    transaction();
  }

  private refundOutstandingTableBalance(playerId: string, roomId: string, reason: string): number {
    const balance = this.tableBalances.get(roomId, playerId);
    const amount = Math.max(0, Math.floor(balance?.amount ?? 0));
    if (!balance || amount <= 0) return 0;
    this.refundWalletAndClearTableBalance(playerId, roomId, balance.currency, amount, reason);
    this.recordLog(`Outstanding table balance refunded: reason=${reason} player_id=${playerId} amount=${amount} room_id=${roomId}`);
    return amount;
  }

  private recoverOutstandingTableBalances(): void {
    const balances = this.tableBalances.allOutstanding();
    for (const balance of balances) {
      this.wallets.ensure(balance.player_id);
      this.refundWalletAndClearTableBalance(balance.player_id, balance.room_id, balance.currency, balance.amount, "server_restart_recovery");
      this.recordLog(`server_restart_recovery player_id=${balance.player_id} room_id=${balance.room_id} amount=${balance.amount} currency=${balance.currency}`);
    }
  }

  private syncRoomTableBalances(room: Room): void {
    if (!room.walletImpact) return;
    const currency = roomCurrency(room) as TableBalanceCurrency;
    const seatedPlayerIds = new Set<string>();
    for (const seat of room.table.seats) {
      if (!seat.playerId || seat.isAi || seat.warmupAi) continue;
      seatedPlayerIds.add(seat.playerId);
      const currentOutstanding = Math.max(0, Math.floor(seat.chips + seat.contribution));
      this.tableBalances.set(room.id, seat.playerId, currency, currentOutstanding);
    }
    for (const balance of this.tableBalances.allForRoom(room.id)) {
      if (!seatedPlayerIds.has(balance.player_id)) this.tableBalances.clear(room.id, balance.player_id);
    }
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
    if (room.mode === "ai_challenge") return;
    if (room.table.phase !== "hand_over") return;
    if (room.isAiWarmup) return;
    const key = `${room.id}:${room.table.handId}`;
    if (this.recordedHandResults.has(key)) return;
    const officialHand = room.officialHandStarted;
    const currency = roomCurrency(room);
    const winnerSeats = new Set(room.table.winners.map((winner) => winner.seat_index));
    this.db.transaction(() => {
      for (const result of room.table.lastHandResults) {
        const seat = room.table.getSeat(result.seat_index);
        if (!seat?.playerId || seat.isAi || seat.warmupAi || seat.serverManagedVirtual) continue;
        this.results.recordHandResult(room.id, room.table.handId, seat.playerId, result.delta, JSON.stringify(result));
        if (officialHand) {
          this.profileBootstrap.recordHandResult(seat.playerId, currency, result.delta, winnerSeats.has(result.seat_index), key);
        }
      }
    })();
    for (const result of room.table.lastHandResults) {
      const seat = room.table.getSeat(result.seat_index);
      if (seat?.serverManagedVirtual) {
        this.virtualPlayers.markHandCompleted(seat.playerId, room.table.handId, seat.chips);
      }
    }
    this.recordedHandResults.add(key);
    if (officialHand) {
      for (const result of room.table.lastHandResults) {
        const seat = room.table.getSeat(result.seat_index);
        if (!seat?.playerId || seat.isAi || seat.warmupAi || seat.serverManagedVirtual) continue;
        const client = this.clients.get(seat.playerId);
        if (client) this.send(client, { type: "profile_snapshot", player_id: seat.playerId, room_id: room.id, ...this.profilePayload(seat.playerId) });
      }
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
    this.settleExpiredDisconnectGrace(room);
    this.syncRoomTableBalances(room);
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
      mode: room.mode === "ai_challenge" ? "ai_challenge" : undefined,
      challenge_id: room.challengeId || undefined,
      wallet_impact: room.walletImpact,
      ...(room.mode === "ai_challenge" && ["hand_over", "session_complete"].includes(room.table.phase)
        ? { hand_result: this.challengeHandResultPayload(room) }
        : {}),
      ...(room.mode === "ai_challenge" && room.sessionComplete ? this.challengeResultPayload(room) : {}),
      seats: this.publicSeatsWithDisconnectGrace(room),
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
    if (room.mode === "ai_challenge" && room.sessionComplete) this.sendChallengeResult(room);
  }

  private encryptedReplayDelivery(room: Room): EncryptedReplayDelivery | undefined {
    const cached = room.replayDeliveries.get(room.table.handId);
    if (cached) return cached;
    const replayId = this.replayIdFactory();
    const keyMaterial = generateReplayKey();
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
    try {
      this.replays.createOfficialReplay(
        {
          replay_id: replayId,
          hand_id: delivery.metadata.hand_id,
          room_id: room.id,
          room_code: room.roomCode,
          table_type: room.tableType,
          currency: roomCurrency(room),
          created_at: createdAt,
          checksum: delivery.checksum,
          schema_version: delivery.metadata.schema_version,
          replay_type: replayTypeForOfficialTable(room.tableType, room.visibility),
          algorithm: delivery.algorithm,
          integrity_status: "valid",
        },
        { replay_id: replayId, key_material: keyMaterial, key_version: delivery.key_version, created_at: createdAt },
        room.table.seats
          .filter((seat) => seat.playerId !== "" && !seat.serverManagedVirtual)
          .map((seat) => ({ player_id: seat.playerId, seat_index: seat.seatIndex })),
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : "unknown_error";
      console.error(`[ReplaySecurity] replay persistence failed replay_id=${replayId} error=${message}`);
      return undefined;
    }
    room.replayDeliveries.set(room.table.handId, delivery);
    return delivery;
  }

  private reconcilePublicVirtualPlayers(room: Room): void {
    void room;
    this.runVirtualScheduler();
  }

  private startVirtualScheduler(): void {
    if (this.virtualSchedulerTimer) return;
    this.virtualSchedulerTimer = setInterval(() => this.runVirtualScheduler(), 1_000);
    (this.virtualSchedulerTimer as { unref?: () => void }).unref?.();
  }

  private runVirtualScheduler(): void {
    try {
      for (const candidateRoom of this.rooms.values()) {
        this.refreshSingleHumanWaitingPeriod(candidateRoom);
        if (candidateRoom.virtualJoinTimer && (
          !this.publicVirtualPlayers.enabled
          || !this.canRoomReceiveNewVirtual(candidateRoom)
        )) {
          this.clearVirtualJoinTimer(candidateRoom);
        }
        this.reconcileVirtualExits(candidateRoom);
      }
      if (!this.publicVirtualPlayers.enabled) {
        this.virtualPlayers.recordSchedulerIdle("global_disabled");
        return;
      }
      if (this.virtualPlayers.onlineCount() >= this.publicVirtualPlayers.maximumOnline) {
        this.virtualPlayers.recordSchedulerIdle("maximum_online_reached");
        return;
      }
      const candidates = [...this.rooms.values()].map((candidateRoom) => this.virtualRoomCandidate(candidateRoom));
      const selected = this.virtualPlayers.selectRoom(candidates);
      if (!selected) {
        this.virtualPlayers.recordSchedulerIdle("no_eligible_public_room");
        return;
      }
      const room = this.rooms.get(selected.roomId);
      if (!room || room.virtualJoinTimer || !["waiting", "hand_over"].includes(room.table.phase)) return;
      this.scheduleVirtualJoin(room);
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error);
      this.virtualPlayers.recordSchedulerError(reason);
      this.recordLog(`virtual_scheduler_error error=${reason}`);
    }
  }

  private reconcileVirtualExits(room: Room): void {
    const virtualSeats = this.virtualPlayerSeats(room);
    if (virtualSeats.length === 0) return;
    const humanSeats = this.realConnectedSeatedCount(room);
    if (!this.isVirtualEligiblePublicRoom(room) || !this.publicVirtualPlayers.enabled || humanSeats === 0) {
      const reason = !this.publicVirtualPlayers.enabled ? "disabled" : humanSeats === 0 ? "no_humans" : "ineligible";
      for (const seat of virtualSeats) this.virtualPlayers.markPendingLeave(seat.playerId, reason);
    }
    this.removeOneSafeVirtualPlayer(room);
  }

  private scheduleVirtualJoin(room: Room): void {
    const profile = this.virtualPlayers.reserveAgent(room.id);
    if (!profile) return;
    const minimum = Math.min(this.publicVirtualPlayers.joinDelayMinMs, this.publicVirtualPlayers.joinDelayMaxMs);
    const maximum = Math.max(this.publicVirtualPlayers.joinDelayMinMs, this.publicVirtualPlayers.joinDelayMaxMs);
    const delay = minimum + Math.floor(Math.random() * (maximum - minimum + 1));
    const token = ++room.virtualJoinToken;
    room.virtualJoiningPlayerId = profile.id;
    room.virtualJoinTimer = setTimeout(() => this.handleVirtualJoin(room.id, token), delay);
    (room.virtualJoinTimer as { unref?: () => void }).unref?.();
  }

  private handleVirtualJoin(roomId: string, token: number): void {
    const room = this.rooms.get(roomId);
    if (!room || token !== room.virtualJoinToken) return;
    room.virtualJoinTimer = undefined;
    const reservedPlayerId = room.virtualJoiningPlayerId;
    room.virtualJoiningPlayerId = "";
    const profile = PUBLIC_VIRTUAL_PLAYER_PROFILES.find((candidate) => candidate.id === reservedPlayerId);
    const blockedReason = !profile
      ? "reservation_missing"
      : !this.virtualPlayers.canCompleteReservation(reservedPlayerId, room.id)
        ? "reservation_invalid"
      : !this.publicVirtualPlayers.enabled
        ? "disabled"
        : !this.isVirtualEligiblePublicRoom(room)
          ? "room_ineligible"
          : this.realConnectedSeatedCount(room) !== 1
            ? "human_count_changed"
            : this.waitingHumanCount(room) > 0
              ? "waiting_human"
              : this.virtualPlayerSeats(room).length > 0
                ? "virtual_already_seated"
                : !this.isVirtualMatchWaitingState(room)
                  ? "room_not_waiting"
                  : "";
    if (blockedReason !== "") {
      if (reservedPlayerId) this.virtualPlayers.releaseReservation(reservedPlayerId, blockedReason);
      this.recordLog(`virtual_join_cancelled player_id=${reservedPlayerId || "-"} room_id=${room.id} reason=${blockedReason}`);
      return;
    }
    const seat = this.firstAvailablePublicSeat(room);
    if (!profile || !seat || this.occupiedSeatCount(room) >= room.maxPlayers) {
      this.virtualPlayers.releaseReservation(reservedPlayerId, "seat_unavailable");
      return;
    }
    room.table.sitDown(
      {
        id: profile.id,
        name: profile.displayName,
        avatarId: profile.avatarId,
        connected: true,
        serverManagedVirtual: true,
      },
      seat.seatIndex,
      room.buyIn,
    );
    room.table.setReady(profile.id, true);
    this.virtualPlayers.markSeated(profile.id, room.id, seat.seatIndex, room.buyIn);
    room.virtualSessionSeeds.set(profile.id, profile.id + ":" + room.id + ":" + randomUUID());
    room.virtualDecisionIndex.set(profile.id, 0);
    this.recordLog(`virtual_player_joined player_id=${profile.id} room_id=${room.id} seat=${seat.seatIndex}`);
    this.updatePublicRoomProgress(room);
    this.schedulePublicVirtualActionIfNeeded(room);
    this.broadcast(room);
    this.reconcilePublicVirtualPlayers(room);
  }

  private schedulePublicVirtualActionIfNeeded(room: Room): void {
    if (room.virtualActionTimer || !isActionPhase(room.table.phase)) return;
    const seat = room.table.getSeat(room.table.currentTurnSeat);
    if (!seat?.serverManagedVirtual || seat.status !== "playing") return;
    const profile = PUBLIC_VIRTUAL_PLAYER_PROFILES.find((candidate) => candidate.id === seat.playerId);
    const minimum = Math.max(this.publicVirtualPlayers.actionDelayMinMs, profile?.actionDelayMinMs ?? 0);
    const maximum = Math.max(minimum, Math.min(this.publicVirtualPlayers.actionDelayMaxMs, profile?.actionDelayMaxMs ?? this.publicVirtualPlayers.actionDelayMaxMs));
    const delay = minimum + Math.floor(Math.random() * (maximum - minimum + 1));
    const token = ++room.virtualActionToken;
    const handId = room.table.handId;
    const turnSeat = room.table.currentTurnSeat;
    room.virtualActionTimer = setTimeout(() => this.performPublicVirtualAction(room.id, seat.playerId, handId, turnSeat, token), delay);
    (room.virtualActionTimer as { unref?: () => void }).unref?.();
  }

  private performPublicVirtualAction(roomId: string, playerId: string, handId: number, turnSeat: number, token: number): void {
    const room = this.rooms.get(roomId);
    if (!room || token !== room.virtualActionToken) return;
    room.virtualActionTimer = undefined;
    if (room.table.handId !== handId || room.table.currentTurnSeat !== turnSeat) return;
    const seat = room.table.getSeat(room.table.currentTurnSeat);
    if (!seat?.serverManagedVirtual || seat.playerId !== playerId || seat.status !== "playing" || !this.virtualPlayers.canAct(playerId, roomId)) return;
    try {
      const profile = PUBLIC_VIRTUAL_PLAYER_PROFILES.find((candidate) => candidate.id === playerId);
      if (!profile) throw new Error("virtual_profile_not_found");
      const legal = legalActions(room.table, playerId);
      this.virtualPlayers.markPlaying(playerId, room.table.handId, seat.chips);
      const decisionIndex = (room.virtualDecisionIndex.get(playerId) ?? 0) + 1;
      room.virtualDecisionIndex.set(playerId, decisionIndex);
      const sessionSeed = room.virtualSessionSeeds.get(playerId) ?? `${playerId}:${room.id}:${randomUUID()}`;
      room.virtualSessionSeeds.set(playerId, sessionSeed);
      const context = buildVirtualBotContext({ botPlayerId: playerId, table: room.table, seatCount: room.maxPlayers, legalActions: legal, handIndex: room.table.handId, decisionIndex, sessionSeed });
      const startedAt = Date.now();
      const decision = decideVirtualPlayerAction(context, profile);
      if (!legalActions(room.table, playerId).some((item) => item.action === decision.action)) throw new Error("virtual_action_no_longer_legal");
      applyPlayerAction(room.table, playerId, decision.action, decision.amount ?? 0);
      processAutomaticTurns(room.table);
      this.virtualPlayers.markAction(playerId, room.table.handId, seat.chips, decision.action);
      this.recordLog(`virtual_player_decision player_id=${playerId} room_id=${room.id} hand_id=${handId} street=${context.street} personality=${decision.personality} decision=${decision.action} raise_to=${decision.raiseTo ?? "-"} internal_reason=${decision.internalReason} internal_strength=${decision.internalStrength} decision_elapsed_ms=${Date.now() - startedAt}`);
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error);
      this.virtualPlayers.markError(playerId, reason);
      this.recordLog(`virtual_player_action_error player_id=${playerId} room_id=${room.id} error=${reason}`);
    }
    this.recordHandResults(room);
    this.updatePublicRoomProgress(room);
    this.reconcilePublicVirtualPlayers(room);
    this.schedulePublicVirtualActionIfNeeded(room);
    this.broadcast(room);
  }
  private isVirtualEligiblePublicRoom(room: Room): boolean {
    return room.mode === "public"
      && room.isPublic
      && room.visibility === "public"
      && (room.tableType === "public_chip" || room.tableType === "public_gem")
      && !room.isAiWarmup
      && !room.sessionComplete;
  }

  private isVirtualMatchWaitingState(room: Room): boolean {
    return ["waiting", "hand_over"].includes(room.table.phase) && !room.sessionComplete;
  }

  private refreshSingleHumanWaitingPeriod(room: Room): void {
    const humanCount = this.realConnectedSeatedCount(room);
    if (!this.isVirtualEligiblePublicRoom(room) || !this.isVirtualMatchWaitingState(room) || humanCount !== 1) {
      room.singleHumanWaitingSinceAt = undefined;
      room.localWarmupStartedAt = undefined;
      return;
    }
    room.singleHumanWaitingSinceAt ??= new Date().toISOString();
    if (room.hostInLocalWarmup === "") room.localWarmupStartedAt = undefined;
  }

  private canRoomReceiveNewVirtual(room: Room): boolean {
    return this.isVirtualEligiblePublicRoom(room)
      && this.isVirtualMatchWaitingState(room)
      && this.realConnectedSeatedCount(room) === 1
      && this.virtualPlayerSeats(room).length === 0
      && this.waitingHumanCount(room) === 0
      && this.occupiedSeatCount(room) < room.maxPlayers
      && this.publicVirtualPlayers.maximumPerRoom > 0;
  }

  private waitingHumanCount(room: Room): number {
    return [...room.clients].filter((playerId) => {
      const client = this.clients.get(playerId);
      return client && !client.devSimulated && !room.table.getSeatByPlayer(playerId);
    }).length;
  }

  private virtualRoomCandidate(room: Room) {
    const virtualCount = this.virtualPlayerSeats(room).length;
    const effectiveWaitingSinceAt = room.localWarmupStartedAt ?? room.singleHumanWaitingSinceAt ?? room.createdAt;
    return {
      roomId: room.id,
      humanCount: this.realConnectedSeatedCount(room),
      virtualCount,
      waitingHumanCount: this.waitingHumanCount(room),
      availableSeats: Math.max(0, room.maxPlayers - this.occupiedSeatCount(room)),
      effectiveWaitingSinceAt,
      roomCreatedAt: room.createdAt,
      eligible: this.canRoomReceiveNewVirtual(room)
        && !room.virtualJoinTimer
        && room.virtualJoiningPlayerId === ""
        && this.virtualPlayers.hasAvailableAgent(),
    };
  }

  private selectVirtualPlayerForLeave(room: Room): Seat | undefined {
    return this.virtualPlayerSeats(room).find((seat) => this.virtualPlayers.isPendingLeave(seat.playerId));
  }

  private virtualPlayerSeats(room: Room): Seat[] {
    return room.table.seats.filter((seat) => seat.serverManagedVirtual && seat.playerId !== "");
  }

  private markRoomVirtualPlayersForLeave(room: Room): void {
    for (const seat of this.virtualPlayerSeats(room)) this.virtualPlayers.markPendingLeave(seat.playerId, "room_shutdown");
    this.clearVirtualJoinTimer(room);
  }

  private removeOneSafeVirtualPlayer(room: Room): void {
    if (!["waiting", "hand_over", "session_complete"].includes(room.table.phase)) return;
    const seat = this.selectVirtualPlayerForLeave(room);
    if (seat && !this.virtualPlayers.isPendingLeave(seat.playerId)) return;
    if (!seat) return;
    const playerId = seat.playerId;
    this.virtualPlayers.markLeaving(playerId);
    room.table.leaveSeat(playerId);
    room.virtualSessionSeeds.delete(playerId);
    room.virtualDecisionIndex.delete(playerId);
    room.virtualActionToken += 1;
    this.virtualPlayers.markOffline(playerId, "safe_leave");
    this.recordLog(`virtual_player_left player_id=${playerId} room_id=${room.id} reason=safe_leave`);
  }

  private clearVirtualJoinTimer(room: Room): void {
    if (room.virtualJoinTimer) clearTimeout(room.virtualJoinTimer);
    room.virtualJoinTimer = undefined;
    if (room.virtualJoiningPlayerId) this.virtualPlayers.releaseReservation(room.virtualJoiningPlayerId, "join_timer_cleared");
    room.virtualJoiningPlayerId = "";
    room.virtualJoinToken += 1;
  }

  private realOnlineCount(): number {
    return [...this.clients.values()].filter((client) => client.ws && client.ws.readyState === client.ws.OPEN).length;
  }

  private virtualAdminSnapshot(): Array<Record<string, unknown>> {
    return this.virtualPlayers.snapshots().map((agent) => ({
      player_kind: agent.playerKind,
      virtual_player_id: agent.playerId,
      display_name: agent.displayName,
      avatar_id: agent.avatarId,
      skill_profile: agent.skillProfile,
      enabled: agent.enabled,
      virtual_state: agent.state,
      room_id: agent.roomId,
      seat: agent.seatIndex,
      chips: agent.chips,
      hand_id: agent.handId,
      session_hands_played: agent.sessionHandsPlayed,
      online_since: agent.onlineSince,
      last_action_at: agent.lastActionAt,
      recent_error: agent.recentError,
      join_block_reason: agent.joinBlockReason,
      pending_leave_reason: agent.pendingLeaveReason,
    }));
  }

  private scheduleChallengeBotIfNeeded(room: Room): void {
    if (room.mode !== "ai_challenge" || room.sessionComplete) return;
    if (!this.challengeSeatsReady(room)) return;
    if (!isActionPhase(room.table.phase)) return;
    const seat = room.table.getSeat(room.table.currentTurnSeat);
    if (!seat || seat.playerId !== room.challengeBotPlayerId || seat.status !== "playing") return;
    if (room.challengeBotTimer) return;
    room.challengeBotTimer = setTimeout(() => this.performChallengeBotAction(room.id), 350);
    (room.challengeBotTimer as { unref?: () => void }).unref?.();
  }

  private clearChallengeBotTimer(room: Room): void {
    if (room.challengeBotTimer) clearTimeout(room.challengeBotTimer);
    room.challengeBotTimer = undefined;
  }

  private performChallengeBotAction(roomId: string): void {
    const room = this.rooms.get(roomId);
    if (!room) return;
    room.challengeBotTimer = undefined;
    if (room.mode !== "ai_challenge" || room.sessionComplete || !isActionPhase(room.table.phase)) return;
    const seat = room.table.getSeat(room.table.currentTurnSeat);
    if (!seat || seat.playerId !== room.challengeBotPlayerId || seat.status !== "playing") return;
    const legal = legalActions(room.table, room.challengeBotPlayerId);
    const context = this.challengeBotContext(room, seat, legal);
    const decision = decideChallengeBotAction(context);
    this.applyChallengeBotDecision(room, decision);
    this.updateChallengeProgress(room);
    this.rescheduleActionTimer(room);
    this.scheduleChallengeBotIfNeeded(room);
    this.broadcast(room);
  }

  private challengeBotContext(room: Room, botSeat: Seat, legal: PrivateSnapshot["legal_actions"]): ChallengeBotContext {
    room.challengeDecisionIndex += 1;
    const playerSeat = room.table.getSeatByPlayer(room.challengePlayerId);
    const call = legal.find((action) => action.action === "call");
    const raise = legal.find((action) => action.action === "raise" || action.action === "bet");
    return {
      botHoleCards: botSeat.holeCards.slice(),
      communityCards: room.table.communityCards.slice(),
      street: room.table.phase as ChallengeBotContext["street"],
      pot: room.table.totalPot(),
      callAmount: Math.max(0, Number(call?.amount ?? (room.table.currentBet - botSeat.currentBet))),
      minRaiseTo: Number.isFinite(raise?.min_amount) ? Number(raise?.min_amount) : null,
      maxRaiseTo: Number.isFinite(raise?.max_amount) ? Number(raise?.max_amount) : null,
      botStack: botSeat.chips,
      playerStack: playerSeat?.chips ?? 0,
      buttonSeat: room.table.dealerSeat,
      botSeat: botSeat.seatIndex,
      legalActions: legal.map((action) => action.action),
      visibleActionHistory: room.table.handActions.map((action) => ({ ...action })),
      handIndex: room.table.handId,
      decisionIndex: room.challengeDecisionIndex,
      sessionSeed: room.challengeSeed,
      botTuning: challengeConfigById(room.challengeId).bot,
    };
  }

  private applyChallengeBotDecision(room: Room, decision: ChallengeBotDecision): void {
    try {
      applyPlayerAction(room.table, room.challengeBotPlayerId, decision.action, decision.amount ?? 0);
      room.table.addAction({ type: "system", action: "ai_challenge_decision", message: `ChallengeRuleBotV1 ${decision.reason}.` });
    } catch (error) {
      const fallback = legalActions(room.table, room.challengeBotPlayerId).some((item) => item.action === "check") ? "check" : "fold";
      applyPlayerAction(room.table, room.challengeBotPlayerId, fallback);
      const reason = error instanceof Error ? error.message : String(error);
      this.recordLog(`ai_challenge_decision_fallback room_id=${room.id} reason=${reason}`);
    }
  }

  private challengeResultPayload(room: Room) {
    const config = challengeConfigById(room.challengeId);
    const player = room.table.getSeatByPlayer(room.challengePlayerId);
    const bot = room.table.getSeatByPlayer(room.challengeBotPlayerId);
    const playerStack = Math.max(0, Math.floor(player?.chips ?? 0));
    const botStack = Math.max(0, Math.floor(bot?.chips ?? 0));
    const settlement = room.settlementResult
      ? { result: room.settlementResult, reason: room.settlementReason ?? "equal_stacks_at_hand_limit" }
      : this.challengeSettlementResult(room);
    const payout = challengePayout(config, settlement.result);
    const displayResult = displayResultForSettlement(settlement.result);
    const reward = room.settlementApplied ? room.walletPayoutChips : payout.walletPayoutChips;
    return {
      result: displayResult,
      challenge_result: displayResult,
      display_result: displayResult,
      settlement_result: settlement.result,
      settlement_reason: settlement.reason,
      settlement_reason_text: settlementReasonText(settlement.reason),
      difficulty: config.displayName,
      entry_fee: config.entryFeeChips,
      entry_fee_chips: config.entryFeeChips,
      reward,
      wallet_payout_chips: reward,
      wallet_net_delta: reward - config.entryFeeChips,
      net_result_chips: reward - config.entryFeeChips,
      player_final_stack: playerStack,
      bot_final_stack: botStack,
      hands_played: this.handsPlayed(room),
      max_hands: config.maxHands,
      win_reason: settlementReasonText(settlement.reason),
    };
  }

  private challengeHandResultPayload(room: Room) {
    const revealedSeatIds = room.table.showdownRevealedSeatIds.slice();
    const showdown = revealedSeatIds.length > 1;
    const winnerSeats = room.table.winners.map((winner) => winner.seat_index);
    const winnerSeat = winnerSeats[0] ?? -1;
    const winner = room.table.getSeat(winnerSeat);
    const playerSeat = room.table.getSeatByPlayer(room.challengePlayerId);
    const opponentSeat = room.table.getSeatByPlayer(room.challengeBotPlayerId);
    const playerResult = room.table.lastHandResults.find((result) => result.seat_index === playerSeat?.seatIndex);
    const handRanks = revealedSeatIds.flatMap((seatIndex) => {
      const seat = room.table.getSeat(seatIndex);
      if (!seat || seat.holeCards.length !== 2 || room.table.communityCards.length !== 5) return [];
      const evaluation = evaluateBestHand([...seat.holeCards, ...room.table.communityCards]);
      return [{
        seat_index: seat.seatIndex,
        player_id: seat.playerId,
        player_name: seat.name,
        hand_rank: evaluation.rank,
        best_cards: evaluation.cards,
      }];
    });
    return {
      hand_id: room.table.handId,
      ended_by_fold: !showdown,
      showdown,
      revealed_hole_cards: revealedSeatIds.flatMap((seatIndex) => {
        const seat = room.table.getSeat(seatIndex);
        if (!seat) return [];
        return [{ seat_index: seat.seatIndex, player_id: seat.playerId, player_name: seat.name, cards: seat.holeCards.slice() }];
      }),
      winner_player_id: winner?.playerId ?? "",
      winner_seat: winnerSeat,
      winner_seats: winnerSeats,
      hand_rank_by_seat: handRanks,
      pot_awarded: room.table.winners.reduce((sum, item) => sum + item.amount, 0),
      player_net_delta: playerResult?.delta ?? 0,
      challenge_hands: this.handsPlayed(room),
      player_stack: Math.max(0, playerSeat?.chips ?? 0),
      opponent_stack: Math.max(0, opponentSeat?.chips ?? 0),
      win_reason: winnerSeats.length > 1
        ? "Split Pot"
        : showdown
          ? "Showdown"
          : winner?.playerId === room.challengePlayerId
            ? "Opponent Folded"
            : "You Folded",
      split_pot: winnerSeats.length > 1,
    };
  }

  private sendChallengeResult(room: Room): void {
    if (room.challengeResultSent) return;
    const client = this.clients.get(room.challengePlayerId);
    if (!client) return;
    this.send(client, {
      type: "ai_challenge_result",
      room_id: room.id,
      challenge_id: room.challengeId,
      wallet: this.wallets.get(room.challengePlayerId),
      ...this.challengeResultPayload(room),
    });
    this.sendWalletSnapshot(client, room.id);
    room.challengeResultSent = true;
  }

  private rescheduleActionTimer(room: Room): void {
    this.clearActionTimer(room);
    if (!isActionPhase(room.table.phase)) return;
    const seat = room.table.getSeat(room.table.currentTurnSeat);
    if (!seat || !seat.playerId || seat.status !== "playing") return;
    if (seat.isAi || seat.warmupAi || seat.serverManagedVirtual || seat.disconnected) return;
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

  private steamAuthenticatedHelloMessage(message: ClientMessage): ClientMessage {
    const provider = normalizeIdentityProvider(String(message.auth_provider || "local_dev"));
    if (provider !== "steam" || this.steamAuthMode === "disabled") return message;
    const ticket = String(message.steam_auth_ticket || "").trim();
    if (ticket === "") {
      if (this.steamAuthMode === "required") throw new Error("steam_ticket_required");
      this.recordLog("steam_auth_warning provider=steam reason=missing_ticket mode=optional");
      return message;
    }
    const expectedIdentity = String(message.steam_auth_identity || config.steamAuthIdentity || "texas-server-v1");
    const result = this.steamAuthVerifier.verifyTicket(ticket, config.steamAppId, expectedIdentity);
    if (!result.valid) throw new Error(result.error_code || "steam_ticket_invalid");
    if (result.app_id && config.steamAppId !== "" && String(result.app_id) !== String(config.steamAppId)) throw new Error("steam_app_mismatch");
    const verifiedSteamId = normalizeExternalId(String(result.steam_id || ""));
    if (verifiedSteamId === "") throw new Error("steam_ticket_invalid");
    const requestedExternalId = normalizeExternalId(String(message.external_id || ""));
    if (requestedExternalId !== "" && requestedExternalId !== verifiedSteamId) throw new Error("steam_identity_mismatch");
    return { ...message, external_id: verifiedSteamId };
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

function boolOrFalse(value: unknown): boolean {
  return value === true;
}

function normalizePurchaseIdempotencyKey(value: string): string {
  const normalized = String(value || "").trim();
  if (!/^[a-zA-Z0-9:_-]{8,128}$/.test(normalized)) throw new Error("invalid_idempotency_key");
  return normalized;
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
