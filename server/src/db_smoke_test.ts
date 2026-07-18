import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { RoomManager } from "./room_manager.js";
import { getDatabase } from "./db/database.js";
import { initializeSchema } from "./db/schema.js";
import { config } from "./config.js";
import { ProfileBootstrapRepository, levelForTotalXp, titleIdForLevel } from "./db/profile_bootstrap_repository.js";
import { LoginBonusRepository } from "./db/login_bonus_repository.js";
import { WalletRepository } from "./db/wallet_repository.js";
import type { SteamAuthVerifier, SteamAuthVerificationResult } from "./services/steam_auth_verifier.js";
import { settleHand } from "./showdown_engine.js";
import Database from "better-sqlite3";
import { migration010PlayerDisplayName } from "./db/migrations/010_player_display_name.js";
import { ReplayRepository } from "./db/replay_repository.js";
import { replayIdFor } from "./replay.js";
import { TableState } from "./table_state.js";

const STARTER_CHIPS = 30000;
const STARTER_GEMS = 500;

const nicknameMigrationDb = new Database(":memory:");
nicknameMigrationDb.exec(`
  CREATE TABLE players (
    player_id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    avatar_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    last_login_at TEXT
  );
  INSERT INTO players (player_id, display_name, avatar_id, created_at, updated_at)
  VALUES ('historical_player', 'Historical Name', 'default', '2026-01-01', '2026-01-01');
`);
migration010PlayerDisplayName.up(nicknameMigrationDb);
migration010PlayerDisplayName.up(nicknameMigrationDb);
const migratedNickname = nicknameMigrationDb
  .prepare("SELECT display_name, steam_persona_name, display_name_updated_at FROM players WHERE player_id = 'historical_player'")
  .get() as { display_name: string; steam_persona_name: string; display_name_updated_at: string | null };
if (migratedNickname.display_name !== "Historical Name" || migratedNickname.steam_persona_name !== "Historical Name") throw new Error("nickname migration should backfill persona without changing display_name");
if (migratedNickname.display_name_updated_at !== null) throw new Error("nickname migration should preserve a free first rename");
nicknameMigrationDb.close();
const DEFAULT_BUY_IN = 2000;

class MockSteamAuthVerifier implements SteamAuthVerifier {
  constructor(private readonly result: SteamAuthVerificationResult = { valid: false, error_code: "steam_ticket_invalid" }) {}

  verifyTicket(): SteamAuthVerificationResult {
    return this.result;
  }
}

interface DisconnectGraceTestAccess {
  disconnectGraceRecords: Map<string, { deadlineAtMs: number; token: number }>;
  handleDisconnectGraceTimeout(roomId: string, playerId: string, token: number): void;
  recordHandResults(room: unknown): void;
  broadcast(room: unknown): void;
}

process.env.TEXAS_DB_PATH = join(mkdtempSync(join(tmpdir(), "texas-db-smoke-")), "texas_dev.sqlite");

const manager = new RoomManager();
const clientMessages: unknown[] = [];
const clientWs = { OPEN: 1, readyState: 1, send: (data: string) => clientMessages.push(JSON.parse(data)) };
const client = manager.connect(clientWs as any);

manager.handle(client.id, { type: "hello", player_id: "db_smoke_player", name: "DB Smoke", avatar_id: "locked_avatar" });

const helloClient = manager.getClient("db_smoke_player");
if (!helloClient) throw new Error("hello did not migrate client to requested player_id");

const firstProfile = manager.adminSnapshot(false);
const firstHello = clientMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { is_new_player?: boolean; profile_snapshot?: { is_new_player?: boolean } }
  | undefined;
if (firstHello?.is_new_player !== true || firstHello.profile_snapshot?.is_new_player !== true) throw new Error("new local_dev hello should mark is_new_player true");
if (Number(firstProfile.player_count) !== 1) throw new Error("expected one player after hello");
if (Number(firstProfile.identity_count) !== 1) throw new Error("expected local_dev identity after hello");
if (Number(firstProfile.total_wallet_chips) !== STARTER_CHIPS) throw new Error("hello should grant starter chips but not auto-claim daily bonus");
if (Number(firstProfile.total_wallet_gems) !== STARTER_GEMS) throw new Error("hello should grant starter gems for new players");
if (Number(firstProfile.avatar_unlock_count) !== 1) throw new Error("new player should unlock the default avatar");
const db = getDatabase();
initializeSchema(db);
if (countRows("schema_migrations") < 9) throw new Error("migrations should be recorded and re-runnable");
if (countRows("player_identities", "provider = 'local_dev' AND external_id = 'db_smoke_player'") !== 1) throw new Error("hello should write local_dev identity");
if (countRows("player_progression", "player_id = 'db_smoke_player' AND total_xp = 0 AND level = 1 AND title_id = 'new_player'") !== 1) throw new Error("local_dev hello should bootstrap default progression");
if (countRows("player_statistics", "player_id = 'db_smoke_player' AND hands_played = 0 AND hands_won = 0 AND chips_won = 0 AND gems_won = 0") !== 1) throw new Error("local_dev hello should bootstrap default statistics");
if (countRows("wallet_transactions", "reason = 'initial_grant' AND currency = 'chips' AND amount = " + STARTER_CHIPS) !== 1) throw new Error("initial chips should write wallet transaction");
if (countRows("wallet_transactions", "reason = 'initial_grant' AND currency = 'gems' AND amount = " + STARTER_GEMS) !== 1) throw new Error("initial gems should write wallet transaction");
if (countRows("wallet_transactions", "reason = 'daily_login_bonus_chips'") !== 0) throw new Error("hello should not write daily login wallet transaction");
const localRepeatMessages: unknown[] = [];
const localRepeatWs = { OPEN: 1, readyState: 1, send: (data: string) => localRepeatMessages.push(JSON.parse(data)) };
const localRepeatClient = manager.connect(localRepeatWs as any);
manager.handle(localRepeatClient.id, { type: "hello", player_id: "db_smoke_player", name: "DB Smoke Again" });
const localRepeatHello = localRepeatMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { player_id?: string; is_new_player?: boolean; profile_snapshot?: { is_new_player?: boolean } }
  | undefined;
if (localRepeatHello?.player_id !== "db_smoke_player") throw new Error("repeat local_dev hello should reuse player_id");
if (localRepeatHello.is_new_player !== false || localRepeatHello.profile_snapshot?.is_new_player !== false) throw new Error("repeat local_dev hello should mark is_new_player false");
if (countRows("wallet_transactions", "player_id = 'db_smoke_player' AND reason = 'initial_grant' AND currency = 'chips' AND amount = " + STARTER_CHIPS) !== 1) throw new Error("repeat local_dev hello should not repeat initial chip grant");
if (countRows("wallet_transactions", "player_id = 'db_smoke_player' AND reason = 'initial_grant' AND currency = 'gems' AND amount = " + STARTER_GEMS) !== 1) throw new Error("repeat local_dev hello should not repeat initial gem grant");
localRepeatMessages.length = 0;
manager.handle("db_smoke_player", { type: "claim_daily_bonus" });
const afterDailyClaim = manager.adminSnapshot(false);
if (Number(afterDailyClaim.total_wallet_chips) !== STARTER_CHIPS + 1000) throw new Error("claim_daily_bonus should grant day 1 chips");
const progressionAfterDailyClaim = db.prepare("SELECT total_xp, level, title_id FROM player_progression WHERE player_id = ?").get("db_smoke_player") as { total_xp: number; level: number; title_id: string };
if (progressionAfterDailyClaim.total_xp !== 25) throw new Error("claim_daily_bonus should persist awarded XP");
if (progressionAfterDailyClaim.level !== levelForTotalXp(progressionAfterDailyClaim.total_xp)) throw new Error("daily bonus level should match authoritative total XP rule");
if (progressionAfterDailyClaim.title_id !== titleIdForLevel(progressionAfterDailyClaim.level)) throw new Error("daily bonus title should match authoritative title rule");
if (countRows("wallet_transactions", "reason = 'daily_login_bonus_chips' AND amount = 1000") !== 1) throw new Error("daily login claim should write chip wallet transaction");
const liveDailyResult = localRepeatMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "daily_bonus_result") as
  | { profile_snapshot?: { wallet?: { chips?: number; gems?: number }; progression?: { total_xp?: number; level?: number; title_id?: string }; daily_bonus?: { already_claimed_today?: boolean } }; daily_bonus_status?: { already_claimed_today?: boolean } }
  | undefined;
if (liveDailyResult?.profile_snapshot?.wallet?.chips !== STARTER_CHIPS + 1000) throw new Error("daily bonus result should include updated profile_snapshot wallet");
if (liveDailyResult.profile_snapshot.progression?.total_xp !== 25 || liveDailyResult.profile_snapshot.progression.level !== 1) throw new Error("daily bonus result should include updated XP and level in profile_snapshot");
if (!liveDailyResult.profile_snapshot.daily_bonus?.already_claimed_today || !liveDailyResult.daily_bonus_status?.already_claimed_today) throw new Error("daily bonus result should include updated claim status");
manager.handle("db_smoke_player", { type: "claim_daily_bonus" });
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== STARTER_CHIPS + 1000) throw new Error("claim_daily_bonus should not award twice on the same day");
const progressionAfterRepeatedDailyClaim = db.prepare("SELECT total_xp, level FROM player_progression WHERE player_id = ?").get("db_smoke_player") as { total_xp: number; level: number };
if (progressionAfterRepeatedDailyClaim.total_xp !== 25 || progressionAfterRepeatedDailyClaim.level !== 1) throw new Error("repeated daily bonus claim should not award XP twice");

const repeatIdentityClient = manager.connect();
manager.handle(repeatIdentityClient.id, { type: "hello", auth_provider: "local_dev", external_id: "db_smoke_player", name: "DB Smoke Repeat" });
if (!manager.getClient("db_smoke_player")) throw new Error("same local_dev external_id should resolve to the same server player_id");

manager.handle("db_smoke_player", { type: "buy_avatar", avatar_id: "1_01" });
const afterAvatarWallet = db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("db_smoke_player") as { chips: number };
if (afterAvatarWallet.chips !== STARTER_CHIPS + 1000 - 1500) throw new Error("buy_avatar should deduct chips from wallet");
if (countRows("avatar_unlocks", "player_id = 'db_smoke_player'") !== 2) throw new Error("buy_avatar should write avatar unlock");
if (countRows("wallet_transactions", "reason = 'avatar_purchase' AND amount = -1500") !== 1) throw new Error("avatar purchase should write negative wallet transaction");
expectThrows("already_unlocked", () => manager.handle("db_smoke_player", { type: "buy_avatar", avatar_id: "1_01" }));
expectThrows("avatar_not_unlocked", () => manager.handle("db_smoke_player", { type: "select_avatar", avatar_id: "2_01" }));
manager.handle("db_smoke_player", { type: "select_avatar", avatar_id: "1_01" });
if (manager.getClient("db_smoke_player")?.avatarId !== "1_01") throw new Error("select_avatar should update selected profile avatar");

manager.handle("db_smoke_player", { type: "hello", player_id: "db_smoke_player", name: "DB Smoke", avatar_id: "default" });
const secondProfile = manager.adminSnapshot(false);
if (Number(secondProfile.player_count) !== 1) throw new Error("second hello should not create another player");
if (Number(secondProfile.total_wallet_chips) !== STARTER_CHIPS + 1000 - 1500) throw new Error("daily login should not award twice on the same day");

const room = manager.createRoom();
manager.handle("db_smoke_player", { type: "join_room", room_id: room.id });
manager.handle("db_smoke_player", { type: "sit_down", room_id: room.id, seat_index: 0, buy_in: 999999 });
const afterBuyIn = manager.adminSnapshot(false);
if (Number(afterBuyIn.total_wallet_chips) !== STARTER_CHIPS + 1000 - 1500 - DEFAULT_BUY_IN) throw new Error("sit_down should deduct room buy-in from wallet");
if (room.table.getSeat(0)?.chips !== DEFAULT_BUY_IN) throw new Error("sit_down should put room buy-in table chips on the seat");
if (countRows("table_balances", "room_id = '" + room.id + "' AND player_id = 'db_smoke_player' AND amount = " + DEFAULT_BUY_IN) !== 1) throw new Error("sit_down should persist outstanding table balance");
manager.handle("db_smoke_player", { type: "sit_down", room_id: room.id, seat_index: 0 });
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== STARTER_CHIPS + 1000 - 1500 - DEFAULT_BUY_IN) throw new Error("repeated sit_down should be idempotent and not deduct wallet twice");
if (countRows("wallet_transactions", "reason = 'table_buy_in' AND related_room_id = '" + room.id + "'") !== 1) throw new Error("repeated sit_down should not write another buy-in transaction");
const creatorSeatSnapshot = room.table.publicSnapshot().seats[0];
if (!creatorSeatSnapshot.occupied) throw new Error("authoritative snapshot should mark creator seat occupied");
if (creatorSeatSnapshot.player_id !== "db_smoke_player") throw new Error("authoritative snapshot should include creator player_id");
if (creatorSeatSnapshot.player_name !== "DB Smoke") throw new Error("authoritative snapshot should include creator name");
if (creatorSeatSnapshot.avatar_id !== "default") throw new Error("authoritative snapshot should include creator avatar_id");
if (!creatorSeatSnapshot.connected) throw new Error("authoritative snapshot should mark creator connected");
if (creatorSeatSnapshot.is_ai) throw new Error("authoritative snapshot should not mark creator as AI");
if (creatorSeatSnapshot.table_stack !== DEFAULT_BUY_IN) throw new Error("authoritative snapshot should expose creator table_stack");
const roomAdminTable = (afterBuyIn.table_list as Array<Record<string, unknown>>).find((table) => table.room_id === room.id);
if (!roomAdminTable) throw new Error("created room should appear in public table list");
if (Number(roomAdminTable.current_players) !== 1) throw new Error("public table list should count one connected real creator");
if (Number(roomAdminTable.seated_count) !== 1) throw new Error("public table list should show creator as 1/6");
if (countRows("wallet_transactions", "reason = 'table_buy_in' AND amount = -" + DEFAULT_BUY_IN) !== 1) throw new Error("table buy-in should write negative wallet transaction");

manager.handle("db_smoke_player", { type: "add_table_chips", room_id: room.id, amount: 500 });
const afterAdd = manager.adminSnapshot(false);
if (Number(afterAdd.total_wallet_chips) !== STARTER_CHIPS + 1000 - 1500 - DEFAULT_BUY_IN - 500) throw new Error("add_table_chips should deduct wallet chips");
if (room.table.getSeat(0)?.chips !== DEFAULT_BUY_IN + 500) throw new Error("add_table_chips should increase table chips");
if (countRows("table_balances", "room_id = '" + room.id + "' AND player_id = 'db_smoke_player' AND amount = " + (DEFAULT_BUY_IN + 500)) !== 1) throw new Error("add_table_chips should increase persisted outstanding table balance");
if (countRows("wallet_transactions", "reason = 'add_table_chips' AND amount = -500") !== 1) throw new Error("add_table_chips should write negative wallet transaction");

expectThrows("insufficient_chips", () => manager.handle("db_smoke_player", { type: "add_table_chips", room_id: room.id, amount: 999999 }));
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== STARTER_CHIPS + 1000 - 1500 - DEFAULT_BUY_IN - 500) throw new Error("failed add_table_chips should not change wallet");

manager.handle("db_smoke_player", { type: "cash_out", room_id: room.id });
const afterCashOut = manager.adminSnapshot(false);
if (Number(afterCashOut.total_wallet_chips) !== STARTER_CHIPS + 1000 - 1500) throw new Error("cash_out should refund remaining table chips");
if (room.table.getSeat(0)?.playerId !== "") throw new Error("cash_out should clear the seat");
if (countRows("table_balances", "room_id = '" + room.id + "' AND player_id = 'db_smoke_player'") !== 0) throw new Error("cash_out should clear persisted outstanding table balance");
if (countRows("wallet_transactions", "reason = 'left_before_official_hand' AND amount = " + (DEFAULT_BUY_IN + 500)) !== 1) throw new Error("pre-hand cash out should write left_before_official_hand wallet transaction");
manager.handle("db_smoke_player", { type: "cash_out", room_id: room.id });
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== STARTER_CHIPS + 1000 - 1500) throw new Error("repeat cash_out should not double refund");

const disconnectRoom = manager.createRoom();
manager.handle("db_smoke_player", { type: "join_room", room_id: disconnectRoom.id });
manager.handle("db_smoke_player", { type: "sit_down", room_id: disconnectRoom.id, seat_index: 0 });
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== STARTER_CHIPS + 1000 - 1500 - DEFAULT_BUY_IN) throw new Error("pre-hand disconnect setup should deduct buy-in");
manager.disconnect("db_smoke_player");
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== STARTER_CHIPS + 1000 - 1500) throw new Error("pre-hand disconnect should refund the full table stack");
if (disconnectRoom.table.getSeat(0)?.playerId !== "") throw new Error("pre-hand disconnect should clear the exited seat");
if (countRows("table_balances", "room_id = '" + disconnectRoom.id + "' AND player_id = 'db_smoke_player'") !== 0) throw new Error("pre-hand disconnect should clear persisted outstanding table balance");
if (countRows("wallet_transactions", "reason = 'left_before_official_hand' AND amount = " + DEFAULT_BUY_IN) < 1) throw new Error("pre-hand disconnect should write left_before_official_hand wallet transaction");

const restartRecoveryClient = manager.connect();
manager.handle(restartRecoveryClient.id, { type: "hello", player_id: "restart_recovery_player", name: "Restart Recovery" });
const restartRecoveryRoom = manager.createRoom();
manager.handle("restart_recovery_player", { type: "join_room", room_id: restartRecoveryRoom.id });
manager.handle("restart_recovery_player", { type: "sit_down", room_id: restartRecoveryRoom.id, seat_index: 0 });
const restartRecoveryWalletAfterBuyIn = (db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("restart_recovery_player") as { chips: number }).chips;
if (restartRecoveryWalletAfterBuyIn !== STARTER_CHIPS - DEFAULT_BUY_IN) throw new Error("restart recovery setup should deduct buy-in before simulated restart");
if (countRows("table_balances", "room_id = '" + restartRecoveryRoom.id + "' AND player_id = 'restart_recovery_player' AND amount = " + DEFAULT_BUY_IN) !== 1) throw new Error("restart recovery setup should persist outstanding table balance");
new RoomManager();
const restartRecoveryWalletAfterRecover = (db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("restart_recovery_player") as { chips: number }).chips;
if (restartRecoveryWalletAfterRecover !== STARTER_CHIPS) throw new Error("server restart recovery should refund outstanding table balance");
if (countRows("table_balances", "room_id = '" + restartRecoveryRoom.id + "' AND player_id = 'restart_recovery_player'") !== 0) throw new Error("server restart recovery should clear outstanding table balance");
if (countRows("wallet_transactions", "reason = 'server_restart_recovery' AND player_id = 'restart_recovery_player' AND amount = " + DEFAULT_BUY_IN) !== 1) throw new Error("server restart recovery should write wallet transaction");

const handRoom = manager.createRoom({ isPublic: false });
manager.handle("db_smoke_player", { type: "join_room", room_id: handRoom.id });
manager.handle("db_smoke_player", { type: "sit_down", room_id: handRoom.id, seat_index: 0 });
manager.handle("db_smoke_player", { type: "ready", room_id: handRoom.id, ready: true });
const second = manager.connect();
manager.handle(second.id, { type: "hello", player_id: "db_smoke_second", name: "DB Smoke 2" });
manager.handle("db_smoke_second", { type: "join_room", room_id: handRoom.id });
manager.handle("db_smoke_second", { type: "sit_down", room_id: handRoom.id, seat_index: 1 });
manager.handle("db_smoke_second", { type: "ready", room_id: handRoom.id, ready: true });
const beforeHandWalletTotal = Number(manager.adminSnapshot(false).total_wallet_chips);
manager.handle("db_smoke_player", { type: "start_hand", room_id: handRoom.id });
expectThrows("cannot_add_chips_during_hand", () => manager.handle("db_smoke_player", { type: "add_table_chips", room_id: handRoom.id, amount: 100 }));
const leavingStack = handRoom.table.getSeat(0)?.chips ?? 0;
const activeHandOutstanding = (handRoom.table.getSeat(0)?.chips ?? 0) + (handRoom.table.getSeat(0)?.contribution ?? 0);
if (countRows("table_balances", "room_id = '" + handRoom.id + "' AND player_id = 'db_smoke_player' AND amount = " + activeHandOutstanding) !== 1) throw new Error("active hand should sync outstanding table balance as stack plus committed contribution");
manager.handle("db_smoke_player", { type: "cash_out", room_id: handRoom.id });
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== beforeHandWalletTotal + leavingStack) throw new Error("active hand cash_out should refund only remaining uncommitted stack");
if (handRoom.table.getSeat(0)?.playerId !== "") throw new Error("active hand cash_out should clear the exited seat after settlement");
if (countRows("table_balances", "room_id = '" + handRoom.id + "' AND player_id = 'db_smoke_player'") !== 0) throw new Error("active hand cash_out should clear persisted table balance for exited player");
if (countRows("wallet_transactions", "reason = 'table_cash_out' AND amount = " + leavingStack) !== 1) throw new Error("active hand cash_out should write table_cash_out wallet transaction");
manager.handle("db_smoke_player", { type: "cash_out", room_id: handRoom.id });
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== beforeHandWalletTotal + leavingStack) throw new Error("repeat active hand cash_out should not double refund");
if (manager.walletAudit("db_smoke_player").unmatchedBuyIns.length !== 0) throw new Error("wallet audit should find no unmatched buy-in after cash outs");

const graceReconnectRoom = manager.createRoom({ isPublic: false });
seatPlayer("grace_reconnect_a", "Grace Reconnect A", graceReconnectRoom.id, 0, true);
seatPlayer("grace_reconnect_b", "Grace Reconnect B", graceReconnectRoom.id, 1, true);
const graceReconnectWalletAfterBuyIn = (db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("grace_reconnect_a") as { chips: number }).chips;
manager.handle("grace_reconnect_a", { type: "start_hand", room_id: graceReconnectRoom.id });
manager.disconnect("grace_reconnect_a");
const graceReconnectSeat = graceReconnectRoom.table.getSeatByPlayer("grace_reconnect_a");
if (!graceReconnectSeat || !graceReconnectSeat.disconnected) throw new Error("active hand disconnect should preserve and mark the seat disconnected");
if ((db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("grace_reconnect_a") as { chips: number }).chips !== graceReconnectWalletAfterBuyIn) throw new Error("active hand disconnect should not immediately refund wallet");
const graceReconnectBalance = db.prepare("SELECT amount FROM table_balances WHERE room_id = ? AND player_id = ?").get(graceReconnectRoom.id, "grace_reconnect_a") as { amount: number } | undefined;
if (!graceReconnectBalance || graceReconnectBalance.amount !== graceReconnectSeat.chips + graceReconnectSeat.contribution) throw new Error("active hand disconnect should preserve outstanding table balance");
const graceReconnectMessages: unknown[] = [];
const graceReconnectWs = { OPEN: 1, readyState: 1, send: (data: string) => graceReconnectMessages.push(JSON.parse(data)) };
const graceReconnectClient = manager.connect(graceReconnectWs as any);
manager.handle(graceReconnectClient.id, { type: "hello", player_id: "grace_reconnect_a", name: "Grace Reconnect A" });
const graceReconnectHello = graceReconnectMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { room_id?: string; reconnected_to_table?: boolean }
  | undefined;
if (!graceReconnectHello?.reconnected_to_table || graceReconnectHello.room_id !== graceReconnectRoom.id) throw new Error("grace reconnect hello should return reconnected_to_table and original room_id");
if (!graceReconnectMessages.some((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "table_snapshot")) throw new Error("grace reconnect should immediately return current table snapshot");
if (!graceReconnectMessages.some((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "private_snapshot")) throw new Error("grace reconnect should immediately return current private snapshot");
const restoredGraceSeat = graceReconnectRoom.table.getSeatByPlayer("grace_reconnect_a");
if (!restoredGraceSeat || restoredGraceSeat.disconnected) throw new Error("grace reconnect should restore the disconnected seat");
if (manager.getClient("grace_reconnect_a")?.roomId !== graceReconnectRoom.id) throw new Error("grace reconnect should bind the client back to the original room");
if ((db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("grace_reconnect_a") as { chips: number }).chips !== graceReconnectWalletAfterBuyIn) throw new Error("grace reconnect should not deduct another buy-in");
if (countRows("wallet_transactions", "reason = 'table_buy_in' AND related_room_id = '" + graceReconnectRoom.id + "' AND player_id = 'grace_reconnect_a'") !== 1) throw new Error("grace reconnect should not write another buy-in transaction");
manager.handle("grace_reconnect_a", { type: "cash_out", room_id: graceReconnectRoom.id });
const graceReconnectWalletAfterCashOut = (db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("grace_reconnect_a") as { chips: number }).chips;
const graceReconnectInternal = manager as unknown as DisconnectGraceTestAccess;
const staleReconnectRecord = graceReconnectInternal.disconnectGraceRecords.get(graceReconnectRoom.id + ":grace_reconnect_a");
if (staleReconnectRecord) {
  staleReconnectRecord.deadlineAtMs = Date.now() - 1;
  graceReconnectInternal.handleDisconnectGraceTimeout(graceReconnectRoom.id, "grace_reconnect_a", staleReconnectRecord.token);
}
if ((db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("grace_reconnect_a") as { chips: number }).chips !== graceReconnectWalletAfterCashOut) throw new Error("cleared grace timeout should not double refund after reconnect cash out");

const graceTimeoutRoom = manager.createRoom({ isPublic: false });
seatPlayer("grace_timeout_a", "Grace Timeout A", graceTimeoutRoom.id, 0, true);
seatPlayer("grace_timeout_b", "Grace Timeout B", graceTimeoutRoom.id, 1, true);
const graceTimeoutWalletAfterBuyIn = (db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("grace_timeout_a") as { chips: number }).chips;
manager.handle("grace_timeout_a", { type: "start_hand", room_id: graceTimeoutRoom.id });
manager.disconnect("grace_timeout_a");
const graceTimeoutSeat = graceTimeoutRoom.table.getSeatByPlayer("grace_timeout_a");
if (!graceTimeoutSeat) throw new Error("grace timeout setup should keep disconnected seat");
const graceTimeoutRemainingStack = graceTimeoutSeat.chips;
const graceTimeoutAccess = manager as unknown as DisconnectGraceTestAccess;
const graceTimeoutRecord = graceTimeoutAccess.disconnectGraceRecords.get(graceTimeoutRoom.id + ":grace_timeout_a");
if (!graceTimeoutRecord) throw new Error("active hand disconnect should create a grace record");
graceTimeoutRecord.deadlineAtMs = Date.now() - 1;
graceTimeoutAccess.handleDisconnectGraceTimeout(graceTimeoutRoom.id, "grace_timeout_a", graceTimeoutRecord.token);
if ((db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("grace_timeout_a") as { chips: number }).chips !== graceTimeoutWalletAfterBuyIn + graceTimeoutRemainingStack) throw new Error("grace expiry after hand over should refund only remaining stack");
if (graceTimeoutRoom.table.getSeatByPlayer("grace_timeout_a")) throw new Error("grace expiry cash out should clear the disconnected seat");
if (countRows("table_balances", "room_id = '" + graceTimeoutRoom.id + "' AND player_id = 'grace_timeout_a'") !== 0) throw new Error("grace expiry cash out should clear table balance");
if (countRows("wallet_transactions", "reason = 'disconnected_grace_expired_cash_out' AND related_room_id = '" + graceTimeoutRoom.id + "' AND player_id = 'grace_timeout_a'") !== 1) throw new Error("grace expiry should write disconnected_grace_expired_cash_out transaction");
graceTimeoutAccess.handleDisconnectGraceTimeout(graceTimeoutRoom.id, "grace_timeout_a", graceTimeoutRecord.token);
if ((db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("grace_timeout_a") as { chips: number }).chips !== graceTimeoutWalletAfterBuyIn + graceTimeoutRemainingStack) throw new Error("repeated grace expiry should not double refund");

const gracePendingRoom = manager.createRoom({ isPublic: false });
seatPlayer("grace_pending_a", "Grace Pending A", gracePendingRoom.id, 0, true);
seatPlayer("grace_pending_b", "Grace Pending B", gracePendingRoom.id, 1, true);
seatPlayer("grace_pending_c", "Grace Pending C", gracePendingRoom.id, 2, true);
const gracePendingWalletAfterBuyIn = (db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("grace_pending_b") as { chips: number }).chips;
manager.handle("grace_pending_a", { type: "start_hand", room_id: gracePendingRoom.id });
manager.disconnect("grace_pending_b");
const gracePendingSeat = gracePendingRoom.table.getSeatByPlayer("grace_pending_b");
if (!gracePendingSeat) throw new Error("pending grace setup should keep disconnected seat");
const gracePendingRemainingStack = gracePendingSeat.chips;
const gracePendingAccess = manager as unknown as DisconnectGraceTestAccess;
const gracePendingRecord = gracePendingAccess.disconnectGraceRecords.get(gracePendingRoom.id + ":grace_pending_b");
if (!gracePendingRecord) throw new Error("non-current active hand disconnect should create a grace record");
gracePendingRecord.deadlineAtMs = Date.now() - 1;
gracePendingAccess.handleDisconnectGraceTimeout(gracePendingRoom.id, "grace_pending_b", gracePendingRecord.token);
if ((db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("grace_pending_b") as { chips: number }).chips !== gracePendingWalletAfterBuyIn) throw new Error("grace expiry during active hand should not refund before hand over");
if (!gracePendingRoom.table.getSeatByPlayer("grace_pending_b")) throw new Error("expired active hand grace should keep the folded seat until settlement");
settleHand(gracePendingRoom.table);
gracePendingAccess.recordHandResults(gracePendingRoom);
gracePendingAccess.broadcast(gracePendingRoom);
if ((db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("grace_pending_b") as { chips: number }).chips !== gracePendingWalletAfterBuyIn + gracePendingRemainingStack) throw new Error("expired grace should cash out remaining stack after hand settlement");
if (gracePendingRoom.table.getSeatByPlayer("grace_pending_b")) throw new Error("expired grace should clear seat after hand settlement cash out");

const poor = manager.connect();
manager.handle(poor.id, { type: "hello", player_id: "db_smoke_poor", name: "DB Smoke Poor" });
const poorRoom = manager.createRoom({ buyIn: 50000, smallBlind: 100, bigBlind: 200, handCount: 20 });
manager.handle("db_smoke_poor", { type: "join_room", room_id: poorRoom.id });
expectThrows("insufficient_chips", () => manager.handle("db_smoke_poor", { type: "sit_down", room_id: poorRoom.id, seat_index: 0 }));

const configClient = manager.connect();
manager.handle(configClient.id, { type: "hello", player_id: "db_smoke_config", name: "DB Smoke Config" });
manager.handle("db_smoke_config", {
  type: "create_table",
  table_name: "Config Test",
  buy_in: 10000,
  small_blind: 50,
  big_blind: 100,
  hand_count: 20,
});
const configAdmin = manager.adminSnapshot(false);
const configTables = configAdmin.table_list as Array<Record<string, unknown>>;
const configTable = configTables.find((table) => table.table_name === "Config Test");
if (!configTable) throw new Error("create_table should add a public table");
if (Number(configTable.buy_in) !== 10000) throw new Error("create_table should preserve selected buy-in");
if (Number(configTable.small_blind) !== 50 || Number(configTable.big_blind) !== 100) throw new Error("create_table should preserve selected blinds");
if (Number(configTable.hand_count) !== 20) throw new Error("create_table should preserve selected hand count");
for (const beginnerBuyIn of [1000, 2000, 5000]) {
  manager.handle("db_smoke_config", {
    type: "create_table",
    table_name: `Beginner ${beginnerBuyIn}`,
    buy_in: beginnerBuyIn,
    small_blind: 25,
    big_blind: 50,
    hand_count: 10,
  });
  const beginnerTable = (manager.adminSnapshot(false).table_list as Array<Record<string, unknown>>).find((table) => table.table_name === `Beginner ${beginnerBuyIn}`);
  if (!beginnerTable || Number(beginnerTable.buy_in) !== beginnerBuyIn) throw new Error("Browser create should support beginner buy-ins");
}

const poorEconomyClient = manager.connect();
manager.handle(poorEconomyClient.id, { type: "hello", player_id: "poor_economy_player", name: "Poor Economy" });
db.prepare("UPDATE wallets SET chips = 999 WHERE player_id = ?").run("poor_economy_player");
const roomsBeforePoorRequests = manager.roomCount();
expectThrows("insufficient_chips", () => manager.handle("poor_economy_player", { type: "quick_join_table", buy_in: 1000, small_blind: 25, big_blind: 50, hand_count: 10, max_players: 6 }));
expectThrows("insufficient_chips", () => manager.handle("poor_economy_player", { type: "create_table", buy_in: 1000, small_blind: 25, big_blind: 50, hand_count: 10 }));
expectThrows("insufficient_chips", () => manager.handle("poor_economy_player", { type: "create_private_table", buy_in: 1000, small_blind: 25, big_blind: 50, hand_count: 10 }));
if (manager.roomCount() !== roomsBeforePoorRequests) throw new Error("insufficient beginner requests must not create rooms");
if (countRows("table_balances", "player_id = 'poor_economy_player'") !== 0) throw new Error("insufficient beginner requests must not create table balance");
if ((db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("poor_economy_player") as { chips: number }).chips !== 999) throw new Error("insufficient beginner requests must not deduct wallet");
expectThrows("invalid_table_config", () => manager.handle("db_smoke_config", { type: "create_table", buy_in: 12345, small_blind: 25, big_blind: 50, hand_count: 10 }));
expectThrows("invalid_table_config", () => manager.handle("db_smoke_config", { type: "create_table", buy_in: 10000, small_blind: 10, big_blind: 20, hand_count: 10 }));

const quickOne = manager.createRoom({ buyIn: 10000, smallBlind: 50, bigBlind: 100, handCount: 10, maxPlayers: 6 });
const quickThree = manager.createRoom({ buyIn: 10000, smallBlind: 50, bigBlind: 100, handCount: 10, maxPlayers: 6 });
seatPlayer("quick_one_a", "Quick One A", quickOne.id, 5);
seatPlayer("quick_three_a", "Quick Three A", quickThree.id, 5);
seatPlayer("quick_three_b", "Quick Three B", quickThree.id, 8);
seatPlayer("quick_three_c", "Quick Three C", quickThree.id, 2);
const quickClient = manager.connect();
manager.handle(quickClient.id, { type: "hello", player_id: "quick_matcher", name: "Quick Matcher" });
manager.handle("quick_matcher", { type: "quick_join_table", buy_in: 10000, small_blind: 50, big_blind: 100, hand_count: 10, max_players: 6 });
if (manager.getClient("quick_matcher")?.roomId !== quickThree.id) throw new Error("quick_join_table should prefer the most populated matching waiting table");

const playingRoom = manager.createRoom({ buyIn: 10000, smallBlind: 25, bigBlind: 50, handCount: 5, maxPlayers: 6 });
seatPlayer("quick_playing_a", "Quick Playing A", playingRoom.id, 5, true);
seatPlayer("quick_playing_b", "Quick Playing B", playingRoom.id, 8, true);
manager.handle("quick_playing_a", { type: "start_hand", room_id: playingRoom.id });
const quickNoPlaying = manager.connect();
manager.handle(quickNoPlaying.id, { type: "hello", player_id: "quick_no_playing", name: "Quick No Playing" });
manager.handle("quick_no_playing", { type: "quick_join_table", buy_in: 10000, small_blind: 25, big_blind: 50, hand_count: 5, max_players: 6 });
if (manager.getClient("quick_no_playing")?.roomId === playingRoom.id) throw new Error("quick_join_table should not join a playing table");

const staleHandOverRoom = manager.createRoom({ buyIn: 20000, smallBlind: 50, bigBlind: 100, handCount: 10, maxPlayers: 6 });
staleHandOverRoom.table.phase = "hand_over";
staleHandOverRoom.officialHandStarted = true;
const staleQuickMessages: unknown[] = [];
const staleQuickWs = { OPEN: 1, readyState: 1, send: (data: string) => staleQuickMessages.push(JSON.parse(data)) };
const staleQuickClient = manager.connect(staleQuickWs as any);
manager.handle(staleQuickClient.id, { type: "hello", player_id: "quick_stale_hand_over", name: "Quick Stale Hand Over" });
manager.handle("quick_stale_hand_over", { type: "quick_join_table", buy_in: 20000, small_blind: 50, big_blind: 100, hand_count: 10, max_players: 6 });
const staleQuickRoomId = manager.getClient("quick_stale_hand_over")?.roomId || "";
if (staleQuickRoomId === staleHandOverRoom.id) throw new Error("quick_join_table should not return stale empty hand_over rooms");
const staleQuickRoom = manager.getRoom(staleQuickRoomId);
if (!staleQuickRoom || staleQuickRoom.table.phase !== "waiting") throw new Error("quick_join_table should create a clean waiting room when stale hand_over rooms are ignored");
const staleQuickMatch = staleQuickMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "quick_table_matched") as
  | { type: string; room_id?: string; table?: { community_cards?: unknown[]; hand_state?: string; room_state?: string } }
  | undefined;
if (!staleQuickMatch || staleQuickMatch.room_id !== staleQuickRoomId) throw new Error("quick_join_table should return the newly matched room id");
if ((staleQuickMatch.table?.community_cards ?? []).length !== 0 || staleQuickMatch.table?.hand_state !== "waiting") throw new Error("quick-created room should not carry stale board or hand state");
expectThrows("room_not_available", () => manager.handle("quick_stale_hand_over", { type: "join_table", room_id: staleHandOverRoom.id }));
const staleSitDownWalletBefore = (db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("quick_stale_hand_over") as { chips: number }).chips;
expectThrows("room_not_available", () => manager.handle("quick_stale_hand_over", { type: "sit_down", room_id: staleHandOverRoom.id, seat_index: 0 }));
expectThrows("room_not_available", () => manager.handle("quick_stale_hand_over", { type: "sit_down", room_id: staleHandOverRoom.id, seat_index: 0 }));
const staleSitDownWalletAfter = (db.prepare("SELECT chips FROM wallets WHERE player_id = ?").get("quick_stale_hand_over") as { chips: number }).chips;
if (staleSitDownWalletAfter !== staleSitDownWalletBefore) throw new Error("repeated failed stale sit_down should not deduct wallet");
if (countRows("wallet_transactions", "reason = 'table_buy_in' AND player_id = 'quick_stale_hand_over'") !== 0) throw new Error("failed stale sit_down should not write buy-in transaction");

const quickCreate = manager.connect();
manager.handle(quickCreate.id, { type: "hello", player_id: "quick_create", name: "Quick Create" });
manager.handle("quick_create", { type: "mock_purchase", currency: "chips", amount: 20000, source: "store_mock" });
manager.handle("quick_create", { type: "quick_join_table", buy_in: 50000, small_blind: 100, big_blind: 200, hand_count: 5, max_players: 6 });
const quickCreatedRoomId = manager.getClient("quick_create")?.roomId || "";
const quickCreatedTable = (manager.adminSnapshot(false).table_list as Array<Record<string, unknown>>).find((table) => table.room_id === quickCreatedRoomId);
if (!quickCreatedTable) throw new Error("quick_join_table should create and list a public table when no match exists");
if (Number(quickCreatedTable.buy_in) !== 50000 || Number(quickCreatedTable.hand_count) !== 5) throw new Error("quick-created table should preserve selected config");

const gemQuickMessages: unknown[] = [];
const gemQuickWs = { OPEN: 1, readyState: 1, send: (data: string) => gemQuickMessages.push(JSON.parse(data)) };
const gemQuick = manager.connect(gemQuickWs as any);
manager.handle(gemQuick.id, { type: "hello", player_id: "gem_quick_player", name: "Gem Quick" });
manager.handle("gem_quick_player", { type: "mock_purchase", currency: "gems", amount: 200, source: "store_mock" });
const gemWalletBeforeBuyIn = Number(manager.adminSnapshot(false).total_wallet_gems);
manager.handle("gem_quick_player", { type: "quick_join_table", table_type: "public_gem", currency: "gems", buy_in: 50, small_blind: 2, big_blind: 5, hand_count: 10, max_players: 6 });
const gemQuickRoomId = manager.getClient("gem_quick_player")?.roomId || "";
const gemQuickRoom = manager.getRoom(gemQuickRoomId);
if (!gemQuickRoom || gemQuickRoom.tableType !== "public_gem") throw new Error("quick_join_table should create public_gem rooms for Gem Quick");
manager.handle("gem_quick_player", { type: "sit_down", room_id: gemQuickRoomId, seat_index: -1 });
if (Number(manager.adminSnapshot(false).total_wallet_gems) !== gemWalletBeforeBuyIn - 50) throw new Error("Gem Quick sit_down should deduct gem buy-in from server wallet");
if (gemQuickRoom.table.getSeatByPlayer("gem_quick_player")?.chips !== 50) throw new Error("Gem Quick seat stack should equal gem buy-in");
const gemQuickAdminTable = (manager.adminSnapshot(false).table_list as Array<Record<string, unknown>>).find((table) => table.room_id === gemQuickRoomId);
if (!gemQuickAdminTable || gemQuickAdminTable.table_type !== "public_gem" || gemQuickAdminTable.currency !== "gems") throw new Error("admin/list table snapshot should expose public_gem currency");
manager.handle("gem_quick_player", { type: "cash_out", room_id: gemQuickRoomId });
if (Number(manager.adminSnapshot(false).total_wallet_gems) !== gemWalletBeforeBuyIn) throw new Error("Gem Quick cash_out should refund remaining Gems");
if (countRows("wallet_transactions", "reason = 'gem_table_buy_in' AND currency = 'gems' AND amount = -50") !== 1) throw new Error("Gem Quick buy-in should write gem_table_buy_in transaction");
if (countRows("wallet_transactions", "reason = 'gem_left_before_official_hand' AND currency = 'gems' AND amount = 50") !== 1) throw new Error("Gem Quick pre-hand cash out should write gem_left_before_official_hand transaction");
const noGemQuick = manager.connect();
manager.handle(noGemQuick.id, { type: "hello", player_id: "no_gem_quick", name: "No Gem Quick" });
db.prepare("UPDATE wallets SET gems = 0 WHERE player_id = ?").run("no_gem_quick");
expectThrows("insufficient_gems", () => manager.handle("no_gem_quick", { type: "quick_join_table", table_type: "public_gem", currency: "gems", buy_in: 50, small_blind: 2, big_blind: 5, hand_count: 10, max_players: 6 }));

const privateCreatorMessages: unknown[] = [];
const privateCreatorWs = { OPEN: 1, readyState: 1, send: (data: string) => privateCreatorMessages.push(JSON.parse(data)) };
const privateCreator = manager.connect(privateCreatorWs as any);
manager.handle(privateCreator.id, { type: "hello", player_id: "private_creator", name: "Private Creator" });
privateCreatorMessages.length = 0;
manager.handle("private_creator", {
  type: "create_private_table",
  buy_in: 10000,
  small_blind: 50,
  big_blind: 100,
  hand_count: 10,
  max_players: 6,
});
const privateCreated = privateCreatorMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "private_table_created") as
  | { type: string; room_id?: string; table?: { room_code?: string; is_public?: boolean; table_type?: string; visibility?: string; buy_in?: number; small_blind?: number; big_blind?: number } }
  | undefined;
if (!privateCreated?.room_id || !privateCreated.table?.room_code) throw new Error("create_private_table should return a room_id and room_code");
if (privateCreated.table.is_public !== false || privateCreated.table.table_type !== "private_chip" || privateCreated.table.visibility !== "private") throw new Error("private table snapshot should be private_chip/private");
if (!/^[A-Z2-9]{4,6}$/.test(privateCreated.table.room_code)) throw new Error("private room code should be a short shareable code");
if (Number(privateCreated.table.buy_in) !== 10000 || Number(privateCreated.table.small_blind) !== 50 || Number(privateCreated.table.big_blind) !== 100) throw new Error("private room should preserve selected setup config");
if ((manager.adminSnapshot(false).table_list as Array<Record<string, unknown>>).some((table) => table.room_id === privateCreated.room_id)) throw new Error("private room should not be listed in public table list");
const privateRoom = manager.getRoom(privateCreated.room_id);
if (!privateRoom) throw new Error("private room should exist after create_private_table");
manager.handle("private_creator", { type: "sit_down", room_id: privateCreated.room_id, seat_index: -1 });
if (privateRoom.table.getSeatByPlayer("private_creator")?.seatIndex !== 5) throw new Error("private creator should sit at objective seat 5");

const privateJoinerMessages: unknown[] = [];
const privateJoinerWs = { OPEN: 1, readyState: 1, send: (data: string) => privateJoinerMessages.push(JSON.parse(data)) };
const privateJoiner = manager.connect(privateJoinerWs as any);
manager.handle(privateJoiner.id, { type: "hello", player_id: "private_joiner", name: "Private Joiner" });
manager.handle("private_joiner", { type: "join_private_table", room_code: privateCreated.table.room_code });
const privateJoined = privateJoinerMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "private_table_joined") as
  | { type: string; room_id?: string; table?: { room_code?: string } }
  | undefined;
if (privateJoined?.room_id !== privateCreated.room_id || privateJoined.table?.room_code !== privateCreated.table.room_code) throw new Error("join_private_table should join by room code");
manager.handle("private_joiner", { type: "sit_down", room_id: privateCreated.room_id, seat_index: -1 });
if (privateRoom.table.getSeatByPlayer("private_joiner")?.seatIndex !== 8) throw new Error("private second player should sit at objective seat 8");
manager.handle("private_creator", { type: "ready", room_id: privateCreated.room_id, ready: true });
manager.handle("private_joiner", { type: "ready", room_id: privateCreated.room_id, ready: true });
manager.handle("private_creator", { type: "start_hand", room_id: privateCreated.room_id });
if (privateRoom.table.phase === "waiting") throw new Error("private room should reuse ready/start hand flow");
expectThrows("room_not_found", () => manager.handle("private_joiner", { type: "join_private_table", room_code: "ZZZZ" }));

const privateGemCreatorMessages: unknown[] = [];
const privateGemCreatorWs = { OPEN: 1, readyState: 1, send: (data: string) => privateGemCreatorMessages.push(JSON.parse(data)) };
const privateGemCreator = manager.connect(privateGemCreatorWs as any);
manager.handle(privateGemCreator.id, { type: "hello", player_id: "private_gem_creator", name: "Private Gem Creator" });
manager.handle("private_gem_creator", { type: "mock_purchase", currency: "gems", amount: 100, source: "store_mock" });
privateGemCreatorMessages.length = 0;
manager.handle("private_gem_creator", { type: "create_private_table", table_type: "private_gem", currency: "gems", buy_in: 50, small_blind: 2, big_blind: 5, hand_count: 5, max_players: 6 });
const privateGemCreated = privateGemCreatorMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "private_table_created") as
  | { type: string; room_id?: string; table?: { room_code?: string; table_type?: string; currency?: string; is_public?: boolean } }
  | undefined;
if (!privateGemCreated?.room_id || privateGemCreated.table?.table_type !== "private_gem" || privateGemCreated.table.currency !== "gems" || privateGemCreated.table.is_public !== false) throw new Error("create_private_table should support private_gem rooms with room codes");
if ((manager.adminSnapshot(false).table_list as Array<Record<string, unknown>>).some((table) => table.room_id === privateGemCreated.room_id)) throw new Error("private_gem room should not be listed in public table list");
const privateGemRoom = manager.getRoom(privateGemCreated.room_id);
if (!privateGemRoom) throw new Error("private_gem room should exist");
manager.handle("private_gem_creator", { type: "sit_down", room_id: privateGemCreated.room_id, seat_index: -1 });
if (privateGemRoom.table.getSeatByPlayer("private_gem_creator")?.chips !== 50) throw new Error("private_gem creator should sit with gem buy-in stack");
const privateGemPoor = manager.connect();
manager.handle(privateGemPoor.id, { type: "hello", player_id: "private_gem_poor", name: "Private Gem Poor" });
db.prepare("UPDATE wallets SET gems = 0 WHERE player_id = ?").run("private_gem_poor");
expectThrows("insufficient_gems", () => manager.handle("private_gem_poor", { type: "join_private_table", room_code: privateGemCreated.table?.room_code || "" }));
const privateGemJoiner = manager.connect();
manager.handle(privateGemJoiner.id, { type: "hello", player_id: "private_gem_joiner", name: "Private Gem Joiner" });
manager.handle("private_gem_joiner", { type: "mock_purchase", currency: "gems", amount: 100, source: "store_mock" });
manager.handle("private_gem_joiner", { type: "join_private_table", room_code: privateGemCreated.table?.room_code || "" });
manager.handle("private_gem_joiner", { type: "sit_down", room_id: privateGemCreated.room_id, seat_index: -1 });
if (privateGemRoom.table.getSeatByPlayer("private_gem_joiner")?.seatIndex !== 8) throw new Error("private_gem room joiner should sit at objective seat 8");
manager.handle("private_gem_creator", { type: "cash_out", room_id: privateGemCreated.room_id });
if (countRows("wallet_transactions", "reason = 'gem_left_before_official_hand' AND related_room_id = '" + privateGemCreated.room_id + "'") !== 1) throw new Error("private_gem pre-hand exit should refund Gems with gem reason");

const quickPrivateMatcher = manager.connect();
manager.handle(quickPrivateMatcher.id, { type: "hello", player_id: "quick_private_matcher", name: "Quick Private Matcher" });
manager.handle("quick_private_matcher", { type: "quick_join_table", buy_in: 10000, small_blind: 50, big_blind: 100, hand_count: 10, max_players: 6 });
if (manager.getClient("quick_private_matcher")?.roomId === privateCreated.room_id) throw new Error("quick_join_table should never match a private room");

const privateFullCreator = manager.connect();
manager.handle(privateFullCreator.id, { type: "hello", player_id: "private_full_creator", name: "Private Full Creator" });
manager.handle("private_full_creator", { type: "create_private_table", buy_in: 5000, small_blind: 25, big_blind: 50, hand_count: 5, max_players: 2 });
const fullRoomId = manager.getClient("private_full_creator")?.roomId || "";
const fullRoom = manager.getRoom(fullRoomId);
if (!fullRoom?.roomCode) throw new Error("full private room should have room code");
manager.handle("private_full_creator", { type: "sit_down", room_id: fullRoomId, seat_index: -1 });
seatPlayer("private_full_second", "Private Full Second", fullRoomId, -1);
const privateFullThird = manager.connect();
manager.handle(privateFullThird.id, { type: "hello", player_id: "private_full_third", name: "Private Full Third" });
expectThrows("table_full", () => manager.handle("private_full_third", { type: "join_private_table", room_code: fullRoom.roomCode }));

const canonicalClient = manager.connect();
manager.handle(canonicalClient.id, { type: "hello", auth_provider: "steam", external_id: "steam_canonical_flow", name: "Canonical Flow" });
const canonicalPlayerId = canonicalClient.id;
if (canonicalPlayerId === "steam_canonical_flow" || canonicalPlayerId === "local_player") throw new Error("steam canonical player_id should be an internal server id");
const identityRoom = manager.createRoom();
manager.handle(canonicalPlayerId, { type: "join_room", room_id: identityRoom.id, player_id: "local_player" });
manager.handle(canonicalPlayerId, { type: "sit_down", room_id: identityRoom.id, seat_index: 0, player_id: "local_player" });
const canonicalSeat = identityRoom.table.getSeat(0);
if (canonicalSeat?.playerId !== canonicalPlayerId) throw new Error("sit_down must use connection canonical player_id, not payload player_id");
manager.handle(canonicalPlayerId, { type: "ready", room_id: identityRoom.id, player_id: "local_player", ready: true });
const canonicalSecond = manager.connect();
manager.handle(canonicalSecond.id, { type: "hello", player_id: "canonical_second", name: "Canonical Second" });
manager.handle("canonical_second", { type: "join_room", room_id: identityRoom.id });
manager.handle("canonical_second", { type: "sit_down", room_id: identityRoom.id, seat_index: 1 });
manager.handle("canonical_second", { type: "ready", room_id: identityRoom.id, ready: true });
manager.handle(canonicalPlayerId, { type: "start_hand", room_id: identityRoom.id, player_id: "local_player" });
const spectator = manager.connect();
manager.handle(spectator.id, { type: "hello", player_id: "canonical_spectator", name: "Canonical Spectator" });
manager.handle("canonical_spectator", { type: "join_room", room_id: identityRoom.id });
expectThrows("player is not seated", () => manager.handle("canonical_spectator", { type: "ready", room_id: identityRoom.id, player_id: canonicalPlayerId, ready: true }));

const steamClient = manager.connect();
manager.handle(steamClient.id, { type: "hello", auth_provider: "steam", external_id: "steam_76561198000000000", name: "Steam Smoke" });
if (countRows("player_identities", "provider = 'steam' AND external_id = 'steam_76561198000000000'") !== 1) throw new Error("steam provider should create identity");
if (manager.getClient("steam_76561198000000000")) throw new Error("server player_id should not directly equal Steam external_id");
expectThrows("invalid_identity_provider", () => manager.handle(manager.connect().id, { type: "hello", auth_provider: "email", external_id: "bad", name: "Bad Provider" }));
expectThrows("external_id is required", () => manager.handle(manager.connect().id, { type: "hello", auth_provider: "steam", external_id: "", name: "Empty External" }));
if (countRows("wallet_transactions") < 7) throw new Error("admin db wallet_transactions query should be readable");
if (countRows("player_identities") < 5) throw new Error("admin db player_identities query should be readable");

const sitAckMessages: unknown[] = [];
const sitAckWs = { OPEN: 1, readyState: 1, send: (data: string) => sitAckMessages.push(JSON.parse(data)) };
const sitAckClient = manager.connect(sitAckWs as any);
manager.handle(sitAckClient.id, { type: "hello", player_id: "sit_ack_player", name: "Sit Ack" });
const sitAckRoom = manager.createRoom();
manager.handle("sit_ack_player", { type: "join_room", room_id: sitAckRoom.id });
sitAckMessages.length = 0;
manager.handle("sit_ack_player", { type: "sit_down", room_id: sitAckRoom.id, seat_index: 0 });
const sitAck = sitAckMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "sit_down_result") as
  | { type: string; ok?: boolean; room_id?: string; seat_index?: number; player_id?: string }
  | undefined;
if (!sitAck || sitAck.ok !== true) throw new Error("sit_down should return sit_down_result ok=true");
if (sitAck.room_id !== sitAckRoom.id || sitAck.seat_index !== 0 || sitAck.player_id !== "sit_ack_player") throw new Error("sit_down_result should include room, seat, and canonical player_id");
if (!sitAckRoom.table.publicSnapshot().seats[0].occupied) throw new Error("sit_down_result success should have occupied snapshot seat");
if (sitAckRoom.table.publicSnapshot().seats[0].player_id !== "sit_ack_player") throw new Error("snapshot seat should use canonical player id after sit_down ack");
const sitFailMessages: unknown[] = [];
const sitFailWs = { OPEN: 1, readyState: 1, send: (data: string) => sitFailMessages.push(JSON.parse(data)) };
const sitFailClient = manager.connect(sitFailWs as any);
manager.handle(sitFailClient.id, { type: "hello", player_id: "sit_fail_player", name: "Sit Fail" });
const sitFailRoom = manager.createRoom({ buyIn: 50000, smallBlind: 100, bigBlind: 200, handCount: 10 });
manager.handle("sit_fail_player", { type: "join_room", room_id: sitFailRoom.id });
sitFailMessages.length = 0;
expectThrows("insufficient_chips", () => manager.handle("sit_fail_player", { type: "sit_down", room_id: sitFailRoom.id, seat_index: 0 }));
const sitFail = sitFailMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "sit_down_result") as
  | { type: string; ok?: boolean; reason?: string; wallet_chips?: number; required_chips?: number }
  | undefined;
if (!sitFail || sitFail.ok !== false || sitFail.reason !== "insufficient_chips") throw new Error("failed sit_down should return sit_down_result ok=false insufficient_chips");
if (Number(sitFail.wallet_chips) >= Number(sitFail.required_chips)) throw new Error("failed sit_down should include wallet_chips below required_chips");

const warmupMessages: unknown[] = [];
const warmupWs = { OPEN: 1, readyState: 1, send: (data: string) => warmupMessages.push(JSON.parse(data)) };
const warmupClient = manager.connect(warmupWs as any);
manager.handle(warmupClient.id, { type: "hello", player_id: "warmup_player", name: "Warmup Player" });
const warmupRoom = manager.createRoom();
manager.handle("warmup_player", { type: "join_room", room_id: warmupRoom.id });
manager.handle("warmup_player", { type: "sit_down", room_id: warmupRoom.id, seat_index: 0 });
const beforeWarmupWallet = Number(manager.adminSnapshot(false).total_wallet_chips);
const beforeWarmupGems = Number(manager.adminSnapshot(false).total_wallet_gems);
warmupMessages.length = 0;
manager.handle("warmup_player", { type: "start_ai_warmup", room_id: warmupRoom.id });
const warmupResult = warmupMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "start_ai_warmup_result") as
  | { type: string; ok?: boolean; room_id?: string; reason?: string; local_warmup?: boolean; is_ai_warmup?: boolean }
  | undefined;
if (!warmupResult || warmupResult.ok !== true || warmupResult.room_id !== warmupRoom.id || warmupResult.local_warmup !== true || warmupResult.is_ai_warmup !== false) throw new Error("start_ai_warmup should acknowledge local warm-up for one seated real player");
const warmupSnapshot = warmupMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "table_snapshot") as
  | { type: string; snapshot?: { is_ai_warmup?: boolean; host_in_local_warmup?: boolean; table_state?: string; current_players?: number; seats?: Array<{ warmup_ai?: boolean; is_ai?: boolean }> } }
  | undefined;
if (!warmupSnapshot?.snapshot?.host_in_local_warmup || warmupSnapshot.snapshot.is_ai_warmup) throw new Error("warm-up snapshot should mark host local warm-up without server ai_warmup");
if ((warmupSnapshot.snapshot.seats ?? []).filter((seat) => seat.warmup_ai || seat.is_ai).length !== 0) throw new Error("start_ai_warmup should not add AI seats to server public room");
if (Number(warmupSnapshot.snapshot.current_players) !== 1) throw new Error("local warm-up should not change server public current_players");
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== beforeWarmupWallet) throw new Error("start_ai_warmup should not change account wallet chips");
if (Number(manager.adminSnapshot(false).total_wallet_gems) !== beforeWarmupGems) throw new Error("start_ai_warmup should not change account wallet gems");
const warmupHandResultRows = countRows("table_session_results");
const warmupBaselineStack = warmupRoom.table.getSeatByPlayer("warmup_player")?.chips ?? 0;
if (warmupRoom.table.phase !== "waiting" || warmupRoom.table.currentTurnSeat !== -1) throw new Error("server room should remain waiting while host runs local warm-up");
if (countRows("table_session_results") !== warmupHandResultRows) throw new Error("local warm-up start should not write formal hand_results");
warmupMessages.length = 0;
manager.handle("warmup_player", { type: "start_ai_warmup", room_id: warmupRoom.id });
const repeatedWarmup = warmupMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "start_ai_warmup_result") as
  | { type: string; ok?: boolean; reason?: string; room_id?: string; local_warmup?: boolean }
  | undefined;
if (!repeatedWarmup || repeatedWarmup.ok !== true || repeatedWarmup.local_warmup !== true) throw new Error("repeated local warm-up start should remain idempotent");
manager.handle("warmup_player", { type: "dev_simulate_real_join", room_id: warmupRoom.id, player_name: "DevPlayer2" });
const joinedSnapshot = warmupMessages.filter((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "table_snapshot").pop() as
  | { type: string; snapshot?: { host_in_local_warmup?: boolean; current_players?: number; seats?: Array<{ player_name?: string; warmup_ai?: boolean; is_ai?: boolean }> } }
  | undefined;
if (!joinedSnapshot?.snapshot || joinedSnapshot.snapshot.host_in_local_warmup) throw new Error("dev simulated real join should interrupt host local warm-up");
if (Number(joinedSnapshot.snapshot.current_players) !== 2) throw new Error("dev simulated real join should return public room to two real players");
if ((joinedSnapshot.snapshot.seats ?? []).filter((seat) => seat.warmup_ai || seat.is_ai).length !== 0) throw new Error("real public room should remain AI-free after join");
if ((joinedSnapshot.snapshot.seats ?? []).filter((seat) => seat.player_name === "DevPlayer2").length !== 1) throw new Error("dev simulated real join should seat DevPlayer2 in the server public room");
expectThrows("Dev simulated player cannot play a real public hand. Use a second client or enable DEV controllable bot.", () => manager.handle("warmup_player", { type: "start_hand", room_id: warmupRoom.id }));
if (warmupRoom.table.phase !== "waiting") throw new Error("dev simulated real player must not be allowed to start a formal public hand");
const beforeWarmupCashOutWallet = Number(manager.adminSnapshot(false).total_wallet_chips);
manager.handle("warmup_player", { type: "cash_out", room_id: warmupRoom.id });
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== beforeWarmupCashOutWallet + warmupBaselineStack) throw new Error("public cash out after local warm-up should refund official table stack only");
if (countRows("wallet_transactions", "reason = 'left_before_official_hand' AND related_room_id = '" + warmupRoom.id + "'") !== 1) throw new Error("local warm-up exit before official hand should refund with left_before_official_hand reason");

const objectiveHost = manager.connect();
manager.handle(objectiveHost.id, { type: "hello", player_id: "objective_host", name: "Objective Host" });
const objectiveJoiner = manager.connect();
manager.handle(objectiveJoiner.id, { type: "hello", player_id: "objective_joiner", name: "Objective Joiner" });
const objectiveRoom = manager.createRoom();
manager.handle("objective_host", { type: "join_room", room_id: objectiveRoom.id });
manager.handle("objective_host", { type: "sit_down", room_id: objectiveRoom.id, seat_index: -1 });
manager.handle("objective_joiner", { type: "join_room", room_id: objectiveRoom.id });
manager.handle("objective_joiner", { type: "sit_down", room_id: objectiveRoom.id, seat_index: -1 });
if (objectiveRoom.table.getSeatByPlayer("objective_host")?.seatIndex !== 5) throw new Error("public create auto-seat should put creator at objective seat 5");
if (objectiveRoom.table.getSeatByPlayer("objective_joiner")?.seatIndex !== 8) throw new Error("public join auto-seat should put second player at objective seat 8");

const readyHostMessages: unknown[] = [];
const readyHostWs = { OPEN: 1, readyState: 1, send: (data: string) => readyHostMessages.push(JSON.parse(data)) };
const readyHost = manager.connect(readyHostWs as any);
manager.handle(readyHost.id, { type: "hello", player_id: "ready_host", name: "Ready Host" });
const readyJoiner = manager.connect();
manager.handle(readyJoiner.id, { type: "hello", player_id: "ready_joiner", name: "Ready Joiner" });
const readyRoom = manager.createRoom();
manager.handle("ready_host", { type: "join_room", room_id: readyRoom.id });
manager.handle("ready_host", { type: "sit_down", room_id: readyRoom.id, seat_index: 0 });
manager.handle("ready_joiner", { type: "join_room", room_id: readyRoom.id });
manager.handle("ready_joiner", { type: "sit_down", room_id: readyRoom.id, seat_index: 1 });
const readySnapshot = readyHostMessages.filter((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "table_snapshot").pop() as
  | { type: string; snapshot?: { table_state?: string; room_state?: string; host_player_id?: string; current_players?: number } }
  | undefined;
if (readySnapshot?.snapshot?.room_state !== "waiting_ready" || readySnapshot.snapshot.table_state !== "waiting_ready") throw new Error("public room should wait for player ready after second real player joins");
if (readySnapshot.snapshot.host_player_id !== "ready_host") throw new Error("waiting_ready snapshot should include host player id");
expectThrows("not_host", () => manager.handle("ready_joiner", { type: "start_hand", room_id: readyRoom.id }));
expectThrows("not_ready_to_start", () => manager.handle("ready_host", { type: "start_hand", room_id: readyRoom.id }));
manager.handle("ready_host", { type: "ready", room_id: readyRoom.id, ready: true });
manager.handle("ready_joiner", { type: "ready", room_id: readyRoom.id, ready: true });
manager.handle("ready_host", { type: "start_hand", room_id: readyRoom.id });
if (readyRoom.table.phase === "waiting") throw new Error("host should be able to start public hand from ready_to_start");
if (readyRoom.table.seats.filter((seat) => seat.isAi || seat.warmupAi).length !== 0) throw new Error("public hand should start with real players only");
readyHostMessages.length = 0;
readyRoom.table.phase = "hand_over";
(manager as unknown as { broadcast(room: typeof readyRoom): void }).broadcast(readyRoom);
const replayHandOverMessage = readyHostMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "table_snapshot") as
  | { type: string; snapshot?: { replay_record?: unknown; replay_delivery?: { replay_id?: string; encrypted_private_blob?: string; metadata?: { checksum?: string }; public_preview?: unknown; checksum?: string; key_version?: number } } }
  | undefined;
if (!replayHandOverMessage?.snapshot?.replay_delivery) throw new Error("official hand_over should send encrypted replay delivery");
if (replayHandOverMessage.snapshot.replay_record) throw new Error("official hand_over should not send plaintext replay_record");
const replayDelivery = replayHandOverMessage.snapshot.replay_delivery;
const replayDeliveryText = JSON.stringify(replayDelivery);
if (replayDeliveryText.includes("hole_cards")) throw new Error("encrypted replay delivery should not expose plaintext hole_cards");
if (replayDeliveryText.includes("replay_key")) throw new Error("encrypted replay delivery should not include replay_key");
if (!String(replayDelivery.encrypted_private_blob || "").includes("AES-256-CBC-HMAC-SHA256")) throw new Error("encrypted replay delivery should use the client-supported encrypted envelope");
if (!String(replayDelivery.encrypted_private_blob || "").includes("ciphertext")) throw new Error("encrypted replay delivery should include encrypted private blob envelope");
const replayId = String(replayDelivery.replay_id || "");
if (replayId === "") throw new Error("encrypted replay delivery should include replay_id");
if (!/^replay_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(replayId)) throw new Error("official replay_id should be a UUID v4 independent of room and hand ids");
const generatedReplayIds = new Set(Array.from({ length: 500 }, () => replayIdFor()));
if (generatedReplayIds.size !== 500) throw new Error("replay UUID generation should not repeat across a large sample");
const restartTableA = new TableState("room_1");
const restartTableB = new TableState("room_1");
restartTableA.handId = 1;
restartTableB.handId = 1;
if (replayIdFor(restartTableA) === replayIdFor(restartTableB)) throw new Error("server restart with reused room/hand ids must still generate distinct replay ids");
if (countRows("replay_index", "replay_id = '" + replayId + "'") !== 1) throw new Error("replay_index should persist encrypted replay metadata");
if (countRows("replay_participants", "replay_id = '" + replayId + "'") < 2) throw new Error("replay_participants should persist hand participants");
if (countRows("replay_keys", "replay_id = '" + replayId + "'") !== 1) throw new Error("replay_keys should persist replay key material");
const replayRepository = new ReplayRepository(db);
const persistedReplay = replayRepository.getReplayIndex(replayId);
const persistedReplayKey = replayRepository.getReplayKey(replayId);
if (!persistedReplay || !persistedReplayKey || persistedReplay.integrity_status !== "valid" || persistedReplay.algorithm !== "AES-256-CBC-HMAC-SHA256") throw new Error("new replay index should persist valid integrity metadata and algorithm");
expectThrows("UNIQUE constraint failed: replay_index.replay_id", () =>
  replayRepository.createOfficialReplay(
    { ...persistedReplay, checksum: "forced-collision-checksum" },
    { ...persistedReplayKey, key_material: "forced-collision-key" },
    [{ player_id: "forced_collision_participant", seat_index: 7 }],
  ),
);
if (replayRepository.getReplayIndex(replayId)?.checksum !== persistedReplay.checksum) throw new Error("duplicate replay transaction must not overwrite the original index");
if (replayRepository.getReplayKey(replayId)?.key_material !== persistedReplayKey.key_material) throw new Error("duplicate replay transaction must not overwrite the original key");
if (replayRepository.isParticipant(replayId, "forced_collision_participant")) throw new Error("duplicate replay transaction must roll back participant inserts");
const replayManagerAccess = manager as unknown as {
  replayIdFactory: () => string;
  encryptedReplayDelivery(room: ReturnType<RoomManager["createRoom"]>): unknown;
};
const originalReplayIdFactory = replayManagerAccess.replayIdFactory;
replayManagerAccess.replayIdFactory = () => replayId;
const forcedCollisionRoom = manager.createRoom();
forcedCollisionRoom.table.handId = 1;
forcedCollisionRoom.table.phase = "hand_over";
const collisionDelivery = replayManagerAccess.encryptedReplayDelivery(forcedCollisionRoom);
replayManagerAccess.replayIdFactory = originalReplayIdFactory;
if (collisionDelivery !== undefined || forcedCollisionRoom.replayDeliveries.size !== 0) throw new Error("failed replay persistence must not cache or send a replay delivery");
if (replayRepository.getReplayIndex(replayId)?.checksum !== persistedReplay.checksum || replayRepository.getReplayKey(replayId)?.key_material !== persistedReplayKey.key_material) throw new Error("failed delivery persistence must preserve original replay metadata and key");
const officialReplayIdentity = {
  replay_id: replayId,
  replay_type: "official_human" as const,
  checksum: String(replayDelivery.checksum || ""),
  key_version: Number(replayDelivery.key_version || 0),
  algorithm: "AES-256-CBC-HMAC-SHA256",
  storage_mode: "official_encrypted",
};
readyHostMessages.length = 0;
manager.handle("ready_host", { type: "get_replay_access", ...officialReplayIdentity });
const initialReplayAccess = readyHostMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "replay_access") as
  | { supported?: boolean; unlocked?: boolean; checksum?: string; key_version?: number; price_gems?: number }
  | undefined;
if (!initialReplayAccess?.supported || initialReplayAccess.unlocked || initialReplayAccess.checksum !== officialReplayIdentity.checksum || initialReplayAccess.key_version !== officialReplayIdentity.key_version || initialReplayAccess.price_gems !== 20) throw new Error("server replay access should be authoritative before unlock");
readyHostMessages.length = 0;
const gemsBeforeMismatchAccess = Number(manager.adminSnapshot(false).total_wallet_gems);
manager.handle("ready_host", { type: "get_replay_access", ...officialReplayIdentity, checksum: "wrong-checksum" });
const mismatchReplayAccess = readyHostMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "replay_access") as
  | { supported?: boolean; unlocked?: boolean; legacy_reason?: string }
  | undefined;
if (mismatchReplayAccess?.supported !== false || mismatchReplayAccess.unlocked !== false || mismatchReplayAccess.legacy_reason !== "checksum_mismatch") throw new Error("mismatched local replay identity should be unsupported without charging");
if (Number(manager.adminSnapshot(false).total_wallet_gems) !== gemsBeforeMismatchAccess) throw new Error("replay access query must never charge gems");
expectThrows("replay_checksum_mismatch", () => manager.handle("ready_host", { type: "unlock_replay", ...officialReplayIdentity, checksum: "wrong-checksum" }));
if (Number(manager.adminSnapshot(false).total_wallet_gems) !== gemsBeforeMismatchAccess) throw new Error("mismatched replay unlock must not charge or return a key");
db.prepare("UPDATE wallets SET gems = 0 WHERE player_id = ?").run("ready_host");
expectThrows("insufficient_gems", () => manager.handle("ready_host", { type: "unlock_replay", ...officialReplayIdentity }));
const replayUnlockNonParticipantMessages: unknown[] = [];
const replayUnlockNonParticipantWs = { OPEN: 1, readyState: 1, send: (data: string) => replayUnlockNonParticipantMessages.push(JSON.parse(data)) };
const replayUnlockNonParticipant = manager.connect(replayUnlockNonParticipantWs as any);
manager.handle(replayUnlockNonParticipant.id, { type: "hello", player_id: "replay_unlock_spectator", name: "Replay Unlock Spectator" });
replayUnlockNonParticipantMessages.length = 0;
manager.handle("replay_unlock_spectator", { type: "get_replay_access", ...officialReplayIdentity });
const spectatorReplayAccess = replayUnlockNonParticipantMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "replay_access") as
  | { participant?: boolean; supported?: boolean; unlocked?: boolean; access_denied_reason?: string }
  | undefined;
if (spectatorReplayAccess?.participant !== false || spectatorReplayAccess.supported !== false || spectatorReplayAccess.unlocked !== false || spectatorReplayAccess.access_denied_reason !== "not_participant") throw new Error("non-participant replay access should return a safe denied state without exposing an unlock action");
expectThrows("replay_access_denied", () => manager.handle("replay_unlock_spectator", { type: "unlock_replay", ...officialReplayIdentity }));
manager.handle("ready_host", { type: "mock_purchase", currency: "gems", amount: 25, source: "store_mock" });
readyHostMessages.length = 0;
const gemsBeforeReplayUnlock = Number(manager.adminSnapshot(false).total_wallet_gems);
manager.handle("ready_host", { type: "unlock_replay", ...officialReplayIdentity });
const replayUnlockMessage = readyHostMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "replay_unlocked") as
  | { type: string; replay_id?: string; replay_type?: string; price_gems?: number; replay_key?: string; key_version?: number; checksum?: string; already_unlocked?: boolean; wallet?: { gems?: number }; profile_snapshot?: { wallet?: { gems?: number }; replay_economy?: { prices?: { official_human?: number; ai?: number; training?: number } } } }
  | undefined;
if (!replayUnlockMessage || replayUnlockMessage.replay_id !== replayId || !replayUnlockMessage.replay_key || replayUnlockMessage.already_unlocked !== false) throw new Error("participant replay unlock should return replay key");
if (replayUnlockMessage.replay_type !== "official_human" || replayUnlockMessage.price_gems !== 20) throw new Error("official replay unlock should use authoritative 20 gem price");
if (replayUnlockMessage.profile_snapshot?.wallet?.gems !== replayUnlockMessage.wallet?.gems) throw new Error("replay unlock should return refreshed authoritative profile wallet");
if (replayUnlockMessage.profile_snapshot?.replay_economy?.prices?.official_human !== 20 || replayUnlockMessage.profile_snapshot?.replay_economy?.prices?.ai !== 10 || replayUnlockMessage.profile_snapshot?.replay_economy?.prices?.training !== 10) throw new Error("profile snapshot should publish authoritative replay economy config");
if (Number(manager.adminSnapshot(false).total_wallet_gems) !== gemsBeforeReplayUnlock - 20) throw new Error("participant replay unlock should deduct gems once");
if (countRows("replay_unlocks", "replay_id = '" + replayId + "' AND player_id = 'ready_host' AND currency = 'gems' AND cost = 20") !== 1) throw new Error("replay unlock should write replay_unlocks record");
if (countRows("wallet_transactions", "reason = 'official_replay_unlock' AND currency = 'gems' AND amount = -20 AND related_room_id = '" + readyRoom.id + "'") !== 1) throw new Error("official replay unlock should write typed wallet transaction");
readyHostMessages.length = 0;
manager.handle("ready_host", { type: "unlock_replay", ...officialReplayIdentity });
const repeatedReplayUnlock = readyHostMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "replay_unlocked") as
  | { type: string; replay_key?: string; already_unlocked?: boolean }
  | undefined;
if (!repeatedReplayUnlock || repeatedReplayUnlock.already_unlocked !== true || repeatedReplayUnlock.replay_key !== replayUnlockMessage.replay_key) throw new Error("repeated replay unlock should return same key without charging");
if (Number(manager.adminSnapshot(false).total_wallet_gems) !== gemsBeforeReplayUnlock - 20) throw new Error("repeated replay unlock should not deduct gems twice");
if (countRows("wallet_transactions", "reason = 'official_replay_unlock' AND currency = 'gems' AND amount = -20 AND related_room_id = '" + readyRoom.id + "'") !== 1) throw new Error("repeated replay unlock should not write another wallet transaction");

for (const localReplayType of ["ai", "training"] as const) {
  const playerId = `${localReplayType}_replay_owner`;
  const messages: unknown[] = [];
  const ws = { OPEN: 1, readyState: 1, send: (data: string) => messages.push(JSON.parse(data)) };
  const client = manager.connect(ws as any);
  manager.handle(client.id, { type: "hello", player_id: playerId, name: `${localReplayType} Replay Owner` });
  const localReplayId = `local_${localReplayType}_replay_001`;
  const gemsBefore = Number((db.prepare("SELECT gems FROM wallets WHERE player_id = ?").get(playerId) as { gems: number }).gems);
  messages.length = 0;
  manager.handle(playerId, { type: "unlock_replay", replay_id: localReplayId, replay_type: localReplayType });
  const unlocked = messages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "replay_unlocked") as
    | { replay_type?: string; price_gems?: number; replay_key?: string; already_unlocked?: boolean; wallet?: { gems?: number }; profile_snapshot?: { wallet?: { gems?: number } } }
    | undefined;
  if (!unlocked || unlocked.replay_type !== localReplayType || unlocked.price_gems !== 10 || unlocked.replay_key) throw new Error(`${localReplayType} replay should unlock for 10 gems without a replay key`);
  if (unlocked.wallet?.gems !== gemsBefore - 10 || unlocked.profile_snapshot?.wallet?.gems !== gemsBefore - 10) throw new Error(`${localReplayType} replay unlock should refresh wallet and profile snapshot`);
  if (countRows("replay_unlocks", `replay_id = '${localReplayId}' AND player_id = '${playerId}' AND cost = 10`) !== 1) throw new Error(`${localReplayType} replay should record one unlock`);
  if (countRows("wallet_transactions", `player_id = '${playerId}' AND reason = '${localReplayType}_replay_unlock' AND amount = -10`) !== 1) throw new Error(`${localReplayType} replay should write typed wallet transaction`);
  messages.length = 0;
  manager.handle(playerId, { type: "unlock_replay", replay_id: localReplayId, replay_type: localReplayType });
  const repeated = messages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "replay_unlocked") as { already_unlocked?: boolean } | undefined;
  if (!repeated?.already_unlocked) throw new Error(`${localReplayType} replay repeated unlock should be idempotent`);
  const gemsAfterRepeat = Number((db.prepare("SELECT gems FROM wallets WHERE player_id = ?").get(playerId) as { gems: number }).gems);
  if (gemsAfterRepeat !== gemsBefore - 10) throw new Error(`${localReplayType} replay repeated unlock should not deduct twice`);
}

const poorTraining = manager.connect();
manager.handle(poorTraining.id, { type: "hello", player_id: "poor_training_replay", name: "Poor Training Replay" });
db.prepare("UPDATE wallets SET gems = 5 WHERE player_id = ?").run("poor_training_replay");
expectThrows("insufficient_gems", () => manager.handle("poor_training_replay", { type: "unlock_replay", replay_id: "local_training_insufficient", replay_type: "training" }));
if (countRows("replay_unlocks", "replay_id = 'local_training_insufficient'") !== 0) throw new Error("insufficient replay unlock must not create entitlement");
if (countRows("wallet_transactions", "player_id = 'poor_training_replay' AND reason = 'training_replay_unlock'") !== 0) throw new Error("insufficient replay unlock must not write wallet transaction");
readyRoom.table.phase = "preflop";
const midJoiner = manager.connect();
manager.handle(midJoiner.id, { type: "hello", player_id: "mid_joiner", name: "Mid Joiner" });
manager.handle("mid_joiner", { type: "join_room", room_id: readyRoom.id });
manager.handle("mid_joiner", { type: "sit_down", room_id: readyRoom.id, seat_index: 2 });
const midSeat = readyRoom.table.getSeatByPlayer("mid_joiner");
if (!midSeat || midSeat.status !== "waiting_next_hand") throw new Error("mid-hand joiner should wait for next hand");
if (midSeat.holeCards.length !== 0) throw new Error("mid-hand joiner should not receive current hand hole cards");
if (readyRoom.table.currentTurnSeat === 2) throw new Error("mid-hand joiner should not enter current turn order");
readyRoom.table.phase = "hand_over";
const handBeforeUnreadyMidJoinerContinue = readyRoom.table.handId;
const readyHostSeatForNextHand = readyRoom.table.getSeatByPlayer("ready_host");
const readyJoinerSeatForNextHand = readyRoom.table.getSeatByPlayer("ready_joiner");
if (readyHostSeatForNextHand) {
  readyHostSeatForNextHand.status = "ready";
  readyHostSeatForNextHand.ready = true;
}
if (readyJoinerSeatForNextHand) {
  readyJoinerSeatForNextHand.status = "ready";
  readyJoinerSeatForNextHand.ready = true;
}
(readyRoom as unknown as { handResultShownHandId: number }).handResultShownHandId = handBeforeUnreadyMidJoinerContinue;
(manager as unknown as { updatePublicRoomProgress(room: typeof readyRoom): void }).updatePublicRoomProgress(readyRoom);
if (readyRoom.table.handId !== handBeforeUnreadyMidJoinerContinue + 1) throw new Error("mid-hand unready joiner should not block ready players from continuing");
if (midSeat.holeCards.length !== 0) throw new Error("mid-hand unready joiner should not receive next hand cards before ready");
manager.handle("mid_joiner", { type: "ready", room_id: readyRoom.id, ready: true });
const nextSeat = readyRoom.table.getSeatByPlayer("mid_joiner");
if (!nextSeat || nextSeat.status !== "waiting_next_hand" || !nextSeat.ready || nextSeat.holeCards.length !== 0) throw new Error("mid-hand joiner should be marked ready for the next hand without joining current hand");
const normalOnePlayer = manager.connect();
manager.handle(normalOnePlayer.id, { type: "hello", player_id: "normal_one_player", name: "Normal One" });
const normalOnePlayerRoom = manager.createRoom();
manager.handle("normal_one_player", { type: "join_room", room_id: normalOnePlayerRoom.id });
manager.handle("normal_one_player", { type: "sit_down", room_id: normalOnePlayerRoom.id, seat_index: 0 });
expectThrows("not_enough_players", () => manager.handle("normal_one_player", { type: "start_hand", room_id: normalOnePlayerRoom.id }));
const nonSeatedWarmupMessages: unknown[] = [];
const nonSeatedWarmupWs = { OPEN: 1, readyState: 1, send: (data: string) => nonSeatedWarmupMessages.push(JSON.parse(data)) };
const nonSeatedWarmup = manager.connect(nonSeatedWarmupWs as any);
manager.handle(nonSeatedWarmup.id, { type: "hello", player_id: "warmup_spectator", name: "Warmup Spectator" });
manager.handle("warmup_spectator", { type: "join_room", room_id: normalOnePlayerRoom.id });
const spectatorBeforeWallet = Number(manager.adminSnapshot(false).total_wallet_chips);
manager.handle("warmup_spectator", { type: "start_ai_warmup", room_id: normalOnePlayerRoom.id });
const spectatorWarmup = nonSeatedWarmupMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "start_ai_warmup_result") as
  | { type: string; ok?: boolean; reason?: string }
  | undefined;
if (!spectatorWarmup || spectatorWarmup.ok !== false || spectatorWarmup.reason !== "not_seated") throw new Error("non-seated player should receive start_ai_warmup_result not_seated");
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== spectatorBeforeWallet) throw new Error("failed start_ai_warmup should not change wallet");

const mockPurchaseMessages: unknown[] = [];
const mockPurchaseWs = { OPEN: 1, readyState: 1, send: (data: string) => mockPurchaseMessages.push(JSON.parse(data)) };
const mockPurchaseClient = manager.connect(mockPurchaseWs as any);
manager.handle(mockPurchaseClient.id, { type: "hello", player_id: "mock_purchase_player", name: "Mock Purchase" });
const localMockHello = mockPurchaseMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { profile_snapshot?: { mock_purchase_allowed?: boolean; mock_purchase_allowed_steam_ids?: unknown } }
  | undefined;
if (localMockHello?.profile_snapshot?.mock_purchase_allowed !== true) throw new Error("dev-enabled local_dev profile should allow mock purchases");
if ("mock_purchase_allowed_steam_ids" in (localMockHello?.profile_snapshot || {})) throw new Error("profile snapshot must not expose mock purchase allowlist");
const beforeMockPurchase = manager.adminSnapshot(false);
manager.handle("mock_purchase_player", { type: "mock_purchase", currency: "chips", amount: 50000, source: "store_mock" });
manager.handle("mock_purchase_player", { type: "mock_purchase", currency: "gems", amount: 500, source: "store_mock" });
const afterMockPurchase = manager.adminSnapshot(false);
if (Number(afterMockPurchase.total_wallet_chips) !== Number(beforeMockPurchase.total_wallet_chips) + 50000) throw new Error("mock chip purchase should update server wallet");
if (Number(afterMockPurchase.total_wallet_gems) !== Number(beforeMockPurchase.total_wallet_gems) + 500) throw new Error("mock gem purchase should update server wallet");
if (countRows("wallet_transactions", "reason = 'store_mock_purchase' AND currency = 'chips' AND amount = 50000") !== 1) throw new Error("mock chip purchase should write wallet transaction");
if (countRows("wallet_transactions", "reason = 'store_mock_purchase' AND currency = 'gems' AND amount = 500") !== 1) throw new Error("mock gem purchase should write wallet transaction");
const purchaseResult = mockPurchaseMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "mock_purchase_result") as
  | { type: string; ok?: boolean; currency?: string; amount?: number; wallet?: { chips?: number; gems?: number }; profile_snapshot?: { wallet?: { chips?: number; gems?: number } } }
  | undefined;
if (!purchaseResult || purchaseResult.ok !== true || purchaseResult.currency !== "chips" || Number(purchaseResult.wallet?.chips) < 50000) throw new Error("mock purchase should return result with synced wallet");
if (purchaseResult.profile_snapshot?.wallet?.chips !== purchaseResult.wallet?.chips) throw new Error("mock purchase should return refreshed profile snapshot wallet");
const affordableRoom = manager.createRoom({ buyIn: 20000, smallBlind: 50, bigBlind: 100, handCount: 10 });
manager.handle("mock_purchase_player", { type: "join_room", room_id: affordableRoom.id });
manager.handle("mock_purchase_player", { type: "sit_down", room_id: affordableRoom.id, seat_index: 0 });
if (!affordableRoom.table.publicSnapshot().seats[0].occupied) throw new Error("mock chip purchase should make selected buy-in affordable");
const beforeDisabledTotal = Number(manager.adminSnapshot(false).total_wallet_chips);
config.allowMockPurchases = false;
expectThrows("mock_purchase_disabled", () => manager.handle("mock_purchase_player", { type: "mock_purchase", currency: "chips", amount: 10000, source: "store_mock" }));
mockPurchaseMessages.length = 0;
manager.handle("mock_purchase_player", { type: "get_profile" });
const disabledMockProfile = mockPurchaseMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "profile_snapshot") as
  | { profile_snapshot?: { mock_purchase_allowed?: boolean } }
  | undefined;
if (disabledMockProfile?.profile_snapshot?.mock_purchase_allowed !== false) throw new Error("globally disabled mock purchases should report false");
config.allowMockPurchases = true;
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== beforeDisabledTotal) throw new Error("disabled mock purchase should not change wallet");
const originalMockAllowlist = config.mockPurchaseAllowedSteamIds;
config.mockPurchaseAllowedSteamIds = ["steam_mock_allowed"];
const deniedSteamMockMessages: unknown[] = [];
const deniedSteamMockWs = { OPEN: 1, readyState: 1, send: (data: string) => deniedSteamMockMessages.push(JSON.parse(data)) };
const deniedSteamMock = manager.connect(deniedSteamMockWs as any);
manager.handle(deniedSteamMock.id, { type: "hello", auth_provider: "steam", external_id: "steam_mock_denied", name: "Denied Mock" });
const deniedSteamMockHello = deniedSteamMockMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { profile_snapshot?: { mock_purchase_allowed?: boolean } }
  | undefined;
if (deniedSteamMockHello?.profile_snapshot?.mock_purchase_allowed !== false) throw new Error("non-allowlisted Steam profile should report mock_purchase_allowed false");
expectThrows("mock_purchase_not_allowed", () => manager.handle(deniedSteamMock.id, { type: "mock_purchase", currency: "gems", amount: 50, source: "store_mock" }));
const allowedSteamMockMessages: unknown[] = [];
const allowedSteamMockWs = { OPEN: 1, readyState: 1, send: (data: string) => allowedSteamMockMessages.push(JSON.parse(data)) };
const allowedSteamMock = manager.connect(allowedSteamMockWs as any);
manager.handle(allowedSteamMock.id, { type: "hello", auth_provider: "steam", external_id: "steam_mock_allowed", name: "Allowed Mock" });
const allowedSteamMockHello = allowedSteamMockMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { player_id?: string; profile_snapshot?: { mock_purchase_allowed?: boolean; mock_purchase_allowed_steam_ids?: unknown } }
  | undefined;
const allowedSteamMockId = String(allowedSteamMockHello?.player_id || "");
if (allowedSteamMockHello?.profile_snapshot?.mock_purchase_allowed !== true) throw new Error("allowlisted Steam profile should report mock_purchase_allowed true");
if ("mock_purchase_allowed_steam_ids" in (allowedSteamMockHello?.profile_snapshot || {})) throw new Error("Steam profile snapshot must not expose mock purchase allowlist");
const beforeAllowedSteamGems = manager.adminSnapshot(false).total_wallet_gems;
manager.handle(allowedSteamMockId, { type: "mock_purchase", currency: "gems", amount: 50, source: "store_mock" });
if (Number(manager.adminSnapshot(false).total_wallet_gems) !== Number(beforeAllowedSteamGems) + 50) throw new Error("allowlisted Steam mock purchase should add gems");
config.mockPurchaseAllowedSteamIds = originalMockAllowlist;

const statsMessagesA: unknown[] = [];
const statsWsA = { OPEN: 1, readyState: 1, send: (data: string) => statsMessagesA.push(JSON.parse(data)) };
const statsClientA = manager.connect(statsWsA as any);
manager.handle(statsClientA.id, { type: "hello", player_id: "stats_player_a", name: "Stats A" });
const statsClientB = manager.connect();
manager.handle(statsClientB.id, { type: "hello", player_id: "stats_player_b", name: "Stats B" });
const statsRoom = manager.createRoom({ tableType: "public_chip" });
statsRoom.table.sitDown({ id: "stats_player_a", name: "Stats A", connected: true }, 0, 1000);
statsRoom.table.sitDown({ id: "stats_player_b", name: "Stats B", connected: true }, 1, 1000);
statsRoom.officialHandStarted = true;
statsRoom.table.handId = 101;
statsRoom.table.phase = "hand_over";
statsRoom.table.lastHandResults = [
  { seat_index: 0, player_name: "Stats A", before_chips: 1000, after_chips: 1150, delta: 150, award: 300 },
  { seat_index: 1, player_name: "Stats B", before_chips: 1000, after_chips: 850, delta: -150, award: 0 },
];
statsRoom.table.winners = [{ seat_index: 0, amount: 300 }];
const recordStats = (targetRoom: typeof statsRoom): void =>
  (manager as unknown as { recordHandResults(room: typeof statsRoom): void }).recordHandResults(targetRoom);
statsMessagesA.length = 0;
recordStats(statsRoom);
let statsA = db.prepare("SELECT * FROM player_statistics WHERE player_id = ?").get("stats_player_a") as { hands_played: number; hands_won: number; chips_won: number; gems_won: number };
let statsB = db.prepare("SELECT * FROM player_statistics WHERE player_id = ?").get("stats_player_b") as { hands_played: number; hands_won: number; chips_won: number; gems_won: number };
if (statsA.hands_played !== 1 || statsB.hands_played !== 1) throw new Error("official hand should increment hands_played for every participant");
if (statsA.hands_won !== 1 || statsB.hands_won !== 0) throw new Error("official hand should increment hands_won only for winners");
if (statsA.chips_won !== 150 || statsB.chips_won !== 0) throw new Error("chip statistics should accumulate only positive net delta");
const pushedStatsAfterHand = statsMessagesA.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "profile_snapshot") as
  | { profile_snapshot?: { statistics?: { hands_played?: number; hands_won?: number; chips_won?: number; gems_won?: number } } }
  | undefined;
if (pushedStatsAfterHand?.profile_snapshot?.statistics?.hands_played !== 1 || pushedStatsAfterHand.profile_snapshot.statistics.hands_won !== 1 || pushedStatsAfterHand.profile_snapshot.statistics.chips_won !== 150) throw new Error("official hand_over should immediately push updated profile statistics");
statsMessagesA.length = 0;
recordStats(statsRoom);
statsA = db.prepare("SELECT * FROM player_statistics WHERE player_id = ?").get("stats_player_a") as typeof statsA;
if (statsA.hands_played !== 1 || statsA.hands_won !== 1 || statsA.chips_won !== 150) throw new Error("repeated processing of one hand should be idempotent");
if (statsMessagesA.some((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "profile_snapshot")) throw new Error("duplicate hand statistics processing should not push duplicate profile snapshots");
if (countRows("hand_statistics_events", "hand_id = '" + statsRoom.id + ":101'") !== 2) throw new Error("official hand should write one statistics event per participant");

statsRoom.table.handId = 102;
statsRoom.table.lastHandResults = [
  { seat_index: 0, player_name: "Stats A", before_chips: 1000, after_chips: 1050, delta: 50, award: 100 },
  { seat_index: 1, player_name: "Stats B", before_chips: 1000, after_chips: 1050, delta: 50, award: 100 },
];
statsRoom.table.winners = [{ seat_index: 0, amount: 100 }, { seat_index: 1, amount: 100 }];
recordStats(statsRoom);
statsA = db.prepare("SELECT * FROM player_statistics WHERE player_id = ?").get("stats_player_a") as typeof statsA;
statsB = db.prepare("SELECT * FROM player_statistics WHERE player_id = ?").get("stats_player_b") as typeof statsB;
if (statsA.hands_played !== 2 || statsB.hands_played !== 2 || statsA.hands_won !== 2 || statsB.hands_won !== 1) throw new Error("split pot winners should each receive hands_won credit");
if (statsA.chips_won !== 200 || statsB.chips_won !== 50) throw new Error("split pot positive chip deltas should accumulate");

const gemStatsRoom = manager.createRoom({ tableType: "public_gem" });
gemStatsRoom.table.sitDown({ id: "stats_player_a", name: "Stats A", connected: true }, 0, 100);
gemStatsRoom.table.sitDown({ id: "stats_player_b", name: "Stats B", connected: true }, 1, 100);
gemStatsRoom.officialHandStarted = true;
gemStatsRoom.table.handId = 201;
gemStatsRoom.table.phase = "hand_over";
gemStatsRoom.table.lastHandResults = [
  { seat_index: 0, player_name: "Stats A", before_chips: 100, after_chips: 107, delta: 7, award: 14 },
  { seat_index: 1, player_name: "Stats B", before_chips: 100, after_chips: 93, delta: -7, award: 0 },
];
gemStatsRoom.table.winners = [{ seat_index: 0, amount: 14 }];
recordStats(gemStatsRoom);
statsA = db.prepare("SELECT * FROM player_statistics WHERE player_id = ?").get("stats_player_a") as typeof statsA;
statsB = db.prepare("SELECT * FROM player_statistics WHERE player_id = ?").get("stats_player_b") as typeof statsB;
if (statsA.gems_won !== 7 || statsB.gems_won !== 0) throw new Error("gem statistics should accumulate only positive net delta");

const eventsBeforeWarmup = countRows("hand_statistics_events");
const statsBeforeWarmup = { ...statsA };
const statsWarmupRoom = manager.createRoom();
statsWarmupRoom.table.sitDown({ id: "stats_player_a", name: "Stats A", connected: true }, 0, 1000);
statsWarmupRoom.isAiWarmup = true;
statsWarmupRoom.officialHandStarted = false;
statsWarmupRoom.table.handId = 301;
statsWarmupRoom.table.phase = "hand_over";
statsWarmupRoom.table.lastHandResults = [{ seat_index: 0, player_name: "Stats A", before_chips: 1000, after_chips: 1100, delta: 100, award: 100 }];
statsWarmupRoom.table.winners = [{ seat_index: 0, amount: 100 }];
recordStats(statsWarmupRoom);
statsA = db.prepare("SELECT * FROM player_statistics WHERE player_id = ?").get("stats_player_a") as typeof statsA;
if (countRows("hand_statistics_events") !== eventsBeforeWarmup || statsA.hands_played !== statsBeforeWarmup.hands_played) throw new Error("AI warm-up should not update authoritative statistics");

statsMessagesA.length = 0;
manager.handle("stats_player_a", { type: "get_profile" });
const updatedStatsProfile = statsMessagesA.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "profile_snapshot") as
  | { profile_snapshot?: { statistics?: { hands_played?: number; hands_won?: number; chips_won?: number; gems_won?: number } } }
  | undefined;
if (updatedStatsProfile?.profile_snapshot?.statistics?.hands_played !== 3 || updatedStatsProfile.profile_snapshot.statistics.hands_won !== 3 || updatedStatsProfile.profile_snapshot.statistics.chips_won !== 200 || updatedStatsProfile.profile_snapshot.statistics.gems_won !== 7) throw new Error("profile refresh should return authoritative updated statistics");

const steamHelloMessages: unknown[] = [];
const steamWs = { OPEN: 1, readyState: 1, send: (data: string) => steamHelloMessages.push(JSON.parse(data)) };
const bootstrapSteamClient = manager.connect(steamWs as any);
manager.handle(bootstrapSteamClient.id, {
  type: "hello",
  auth_provider: "steam",
  external_id: "76561198000000006",
  name: "Steam Bootstrap",
});
const steamHello = steamHelloMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | {
      player_id?: string;
      is_new_player?: boolean;
      profile_snapshot?: {
        player_id?: string;
        display_name?: string;
        steam_persona_name?: string;
        steam_id?: string;
        is_new_player?: boolean;
        avatar_id?: string;
        wallet?: { chips?: number; gems?: number };
        progression?: { total_xp?: number; level?: number; title_id?: string };
        statistics?: { hands_played?: number; hands_won?: number; chips_won?: number; gems_won?: number };
        unlocked_avatar_ids?: string[];
        daily_bonus?: { can_claim_today?: boolean };
        created_at?: string;
        updated_at?: string;
      };
    }
  | undefined;
const steamPlayerId = String(steamHello?.player_id || "");
if (steamPlayerId === "" || steamPlayerId === "76561198000000006") throw new Error("new Steam identity should receive a distinct internal player_id");
if (steamHello?.profile_snapshot?.player_id !== steamPlayerId) throw new Error("hello should return a unified profile_snapshot");
if (steamHello.profile_snapshot.display_name !== "Steam Bootstrap" || steamHello.profile_snapshot.avatar_id !== "default") throw new Error("profile_snapshot should include player identity fields");
if (steamHello.profile_snapshot.steam_persona_name !== "Steam Bootstrap" || steamHello.profile_snapshot.steam_id !== "76561198000000006") throw new Error("new Steam profile should separate Steam identity fields");
if (steamHello.profile_snapshot.wallet?.chips !== STARTER_CHIPS || steamHello.profile_snapshot.wallet?.gems !== STARTER_GEMS) throw new Error("new Steam profile_snapshot should include initial wallet");
if (steamHello.profile_snapshot.progression?.total_xp !== 0 || steamHello.profile_snapshot.progression?.level !== 1 || steamHello.profile_snapshot.progression?.title_id !== "new_player") throw new Error("new Steam profile_snapshot should include default progression");
if (steamHello.profile_snapshot.statistics?.hands_played !== 0 || steamHello.profile_snapshot.statistics?.hands_won !== 0 || steamHello.profile_snapshot.statistics?.chips_won !== 0 || steamHello.profile_snapshot.statistics?.gems_won !== 0) throw new Error("new Steam profile_snapshot should include default statistics");
if (!steamHello.profile_snapshot.unlocked_avatar_ids?.includes("default")) throw new Error("new Steam profile_snapshot should include default avatar unlock");
if (!steamHello.profile_snapshot.daily_bonus || !steamHello.profile_snapshot.created_at || !steamHello.profile_snapshot.updated_at) throw new Error("profile_snapshot should include daily bonus and timestamps");
if (steamHello.is_new_player !== true || steamHello.profile_snapshot.is_new_player !== true) throw new Error("new Steam hello should mark is_new_player true");

db.prepare("UPDATE wallets SET chips = 8765 WHERE player_id = ?").run(steamPlayerId);
db.prepare("UPDATE player_progression SET total_xp = 450, level = 5, title_id = 'table_regular' WHERE player_id = ?").run(steamPlayerId);
db.prepare("UPDATE player_statistics SET hands_played = 12, hands_won = 4, chips_won = 2300, gems_won = 2 WHERE player_id = ?").run(steamPlayerId);
const steamRepeatMessages: unknown[] = [];
const steamRepeatWs = { OPEN: 1, readyState: 1, send: (data: string) => steamRepeatMessages.push(JSON.parse(data)) };
const steamRepeatClient = manager.connect(steamRepeatWs as any);
manager.handle(steamRepeatClient.id, {
  type: "hello",
  auth_provider: "steam",
  external_id: "76561198000000006",
  name: "Renamed Steam Persona",
});
const steamRepeatHello = steamRepeatMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { player_id?: string; is_new_player?: boolean; profile_snapshot?: { is_new_player?: boolean; display_name?: string; steam_persona_name?: string; steam_id?: string; wallet?: { chips?: number }; progression?: { total_xp?: number; level?: number; title_id?: string }; statistics?: { hands_played?: number; hands_won?: number; chips_won?: number; gems_won?: number } } }
  | undefined;
if (steamRepeatHello?.player_id !== steamPlayerId) throw new Error("same Steam external_id should reuse internal player_id");
if (steamRepeatHello.is_new_player !== false || steamRepeatHello.profile_snapshot?.is_new_player !== false) throw new Error("repeat Steam hello should mark is_new_player false");
if (steamRepeatHello.profile_snapshot?.display_name !== "Steam Bootstrap") throw new Error("Steam persona change must not overwrite game display_name");
if (steamRepeatHello.profile_snapshot.steam_persona_name !== "Renamed Steam Persona" || steamRepeatHello.profile_snapshot.steam_id !== "76561198000000006") throw new Error("Steam persona change should update only Steam profile data");
if (steamRepeatHello.profile_snapshot.wallet?.chips !== 8765) throw new Error("repeat Steam hello should not reset wallet");
if (steamRepeatHello.profile_snapshot.progression?.total_xp !== 450 || steamRepeatHello.profile_snapshot.progression?.level !== 5 || steamRepeatHello.profile_snapshot.progression?.title_id !== "table_regular") throw new Error("repeat Steam hello should not reset progression");
if (steamRepeatHello.profile_snapshot.statistics?.hands_played !== 12 || steamRepeatHello.profile_snapshot.statistics?.hands_won !== 4 || steamRepeatHello.profile_snapshot.statistics?.chips_won !== 2300 || steamRepeatHello.profile_snapshot.statistics?.gems_won !== 2) throw new Error("repeat Steam hello should not reset statistics");
const steamInitialChipGrants = db.prepare("SELECT COUNT(*) AS count FROM wallet_transactions WHERE player_id = ? AND reason = 'initial_grant' AND currency = 'chips'").get(steamPlayerId) as { count: number };
const steamInitialGemGrants = db.prepare("SELECT COUNT(*) AS count FROM wallet_transactions WHERE player_id = ? AND reason = 'initial_grant' AND currency = 'gems'").get(steamPlayerId) as { count: number };
if (Number(steamInitialChipGrants.count) !== 1 || Number(steamInitialGemGrants.count) !== 1) throw new Error("repeat Steam hello should not repeat initial wallet grant");
const steamDefaultUnlocks = db.prepare("SELECT COUNT(*) AS count FROM avatar_unlocks WHERE player_id = ? AND avatar_id = 'default'").get(steamPlayerId) as { count: number };
if (Number(steamDefaultUnlocks.count) !== 1) throw new Error("repeat Steam hello should not repeat default avatar unlock");

expectThrows("display_name_reserved", () => manager.handle(steamPlayerId, { type: "rename_display_name", display_name: "  Admin  " }));
expectThrows("invalid_display_name", () => manager.handle(steamPlayerId, { type: "rename_display_name", display_name: "ab" }));
steamRepeatMessages.length = 0;
manager.handle(steamPlayerId, { type: "rename_display_name", display_name: "  River   Reader  " });
const renamedSteamProfile = steamRepeatMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "profile_snapshot") as
  | { profile_snapshot?: { player_id?: string; display_name?: string; steam_persona_name?: string; steam_id?: string; display_name_updated_at?: string | null } }
  | undefined;
if (renamedSteamProfile?.profile_snapshot?.display_name !== "River Reader") throw new Error("first display name rename should trim and collapse whitespace");
if (!renamedSteamProfile.profile_snapshot.display_name_updated_at) throw new Error("first display name rename should set cooldown timestamp");
if (renamedSteamProfile.profile_snapshot.steam_persona_name !== "Renamed Steam Persona") throw new Error("display name rename must not change Steam persona");
if (renamedSteamProfile.profile_snapshot.player_id !== steamPlayerId || renamedSteamProfile.profile_snapshot.steam_id !== "76561198000000006") throw new Error("display name rename must not change player identity");
expectThrows("display_name_cooldown", () => manager.handle(steamPlayerId, { type: "rename_display_name", display_name: "Second Rename" }));
db.prepare("UPDATE players SET display_name_updated_at = ? WHERE player_id = ?").run("2026-01-01T00:00:00.000Z", steamPlayerId);
steamRepeatMessages.length = 0;
manager.handle(steamPlayerId, { type: "rename_display_name", display_name: "After Cooldown" });
const afterCooldownProfile = steamRepeatMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "profile_snapshot") as
  | { profile_snapshot?: { display_name?: string; steam_persona_name?: string } }
  | undefined;
if (afterCooldownProfile?.profile_snapshot?.display_name !== "After Cooldown" || afterCooldownProfile.profile_snapshot.steam_persona_name !== "Renamed Steam Persona") throw new Error("rename should succeed after cooldown without changing Steam persona");

db.prepare("DELETE FROM table_balances").run();
const originalSteamAppId = config.steamAppId;
config.steamAppId = "480";
const optionalNoTicketMessages: unknown[] = [];
const optionalNoTicketWs = { OPEN: 1, readyState: 1, send: (data: string) => optionalNoTicketMessages.push(JSON.parse(data)) };
const optionalNoTicketManager = new RoomManager({ steamAuthMode: "optional", steamAuthVerifier: new MockSteamAuthVerifier() });
const optionalNoTicketClient = optionalNoTicketManager.connect(optionalNoTicketWs as any);
optionalNoTicketManager.handle(optionalNoTicketClient.id, { type: "hello", auth_provider: "steam", external_id: "76561198000000008", name: "Optional No Ticket" });
const optionalNoTicketHello = optionalNoTicketMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { player_id?: string }
  | undefined;
if (!optionalNoTicketHello?.player_id || optionalNoTicketHello.player_id === "76561198000000008") throw new Error("optional Steam auth should allow missing ticket during scaffold");

const optionalValidMessages: unknown[] = [];
const optionalValidWs = { OPEN: 1, readyState: 1, send: (data: string) => optionalValidMessages.push(JSON.parse(data)) };
const optionalValidManager = new RoomManager({ steamAuthMode: "optional", steamAuthVerifier: new MockSteamAuthVerifier({ valid: true, steam_id: "76561198000000009", app_id: "480" }) });
const optionalValidClient = optionalValidManager.connect(optionalValidWs as any);
optionalValidManager.handle(optionalValidClient.id, {
  type: "hello",
  auth_provider: "steam",
  external_id: "76561198000000009",
  name: "Optional Valid",
  steam_auth_ticket: "aabbcc",
  steam_auth_identity: "texas-server-v1",
});
const optionalValidHello = optionalValidMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { player_id?: string }
  | undefined;
if (!optionalValidHello?.player_id || optionalValidHello.player_id === "76561198000000009") throw new Error("valid Steam ticket should authenticate and map to internal player_id");
if (JSON.stringify(optionalValidMessages).includes("aabbcc")) throw new Error("Steam auth ticket should not be echoed to client responses");

const optionalValidRepeatMessages: unknown[] = [];
const optionalValidRepeatWs = { OPEN: 1, readyState: 1, send: (data: string) => optionalValidRepeatMessages.push(JSON.parse(data)) };
const optionalValidRepeatClient = optionalValidManager.connect(optionalValidRepeatWs as any);
optionalValidManager.handle(optionalValidRepeatClient.id, {
  type: "hello",
  auth_provider: "steam",
  external_id: "76561198000000009",
  name: "Optional Valid Again",
  steam_auth_ticket: "ddeeff",
  steam_auth_identity: "texas-server-v1",
});
const optionalValidRepeatHello = optionalValidRepeatMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { player_id?: string }
  | undefined;
if (optionalValidRepeatHello?.player_id !== optionalValidHello.player_id) throw new Error("same verified SteamID should reuse internal player_id");

expectThrows("steam_ticket_required", () => {
  const requiredManager = new RoomManager({ steamAuthMode: "required", steamAuthVerifier: new MockSteamAuthVerifier() });
  const requiredClient = requiredManager.connect();
  requiredManager.handle(requiredClient.id, { type: "hello", auth_provider: "steam", external_id: "76561198000000010", name: "Required Missing" });
});
expectThrows("steam_ticket_invalid", () => {
  const invalidManager = new RoomManager({ steamAuthMode: "required", steamAuthVerifier: new MockSteamAuthVerifier({ valid: false, error_code: "steam_ticket_invalid" }) });
  const invalidClient = invalidManager.connect();
  invalidManager.handle(invalidClient.id, { type: "hello", auth_provider: "steam", external_id: "76561198000000010", name: "Invalid Ticket", steam_auth_ticket: "aabbcc" });
});
expectThrows("steam_app_mismatch", () => {
  const appMismatchManager = new RoomManager({ steamAuthMode: "required", steamAuthVerifier: new MockSteamAuthVerifier({ valid: true, steam_id: "76561198000000010", app_id: "999" }) });
  const appMismatchClient = appMismatchManager.connect();
  appMismatchManager.handle(appMismatchClient.id, { type: "hello", auth_provider: "steam", external_id: "76561198000000010", name: "App Mismatch", steam_auth_ticket: "aabbcc" });
});
expectThrows("steam_identity_mismatch", () => {
  const identityMismatchManager = new RoomManager({ steamAuthMode: "required", steamAuthVerifier: new MockSteamAuthVerifier({ valid: true, steam_id: "76561198000000011", app_id: "480" }) });
  const identityMismatchClient = identityMismatchManager.connect();
  identityMismatchManager.handle(identityMismatchClient.id, { type: "hello", auth_provider: "steam", external_id: "76561198000000010", name: "Identity Mismatch", steam_auth_ticket: "aabbcc" });
});
config.steamAppId = originalSteamAppId;

const historicalCreatedAt = new Date().toISOString();
db.prepare("INSERT INTO players (player_id, display_name, avatar_id, created_at, updated_at) VALUES (?, ?, 'default', ?, ?)").run(
  "legacy_steam_player",
  "Legacy Before Bootstrap",
  historicalCreatedAt,
  historicalCreatedAt,
);
db.prepare("INSERT INTO wallets (player_id, chips, gems, updated_at) VALUES (?, 4321, 9, ?)").run("legacy_steam_player", historicalCreatedAt);
db.prepare("INSERT INTO player_identities (id, player_id, provider, external_id, created_at) VALUES (?, ?, 'steam', ?, ?)").run(
  "identity_legacy_steam_player",
  "legacy_steam_player",
  "76561198000000007",
  historicalCreatedAt,
);
if (countRows("player_progression", "player_id = 'legacy_steam_player'") !== 0) throw new Error("legacy fixture should start without progression");
if (countRows("player_statistics", "player_id = 'legacy_steam_player'") !== 0) throw new Error("legacy fixture should start without statistics");
const legacyMessages: unknown[] = [];
const legacyWs = { OPEN: 1, readyState: 1, send: (data: string) => legacyMessages.push(JSON.parse(data)) };
const legacyClient = manager.connect(legacyWs as any);
manager.handle(legacyClient.id, {
  type: "hello",
  auth_provider: "steam",
  external_id: "76561198000000007",
  name: "Legacy Luna",
});
const legacyHello = legacyMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { player_id?: string; is_new_player?: boolean; profile_snapshot?: { is_new_player?: boolean; display_name?: string; steam_persona_name?: string; steam_id?: string; wallet?: { chips?: number; gems?: number }; progression?: { total_xp?: number; level?: number; title_id?: string }; statistics?: { hands_played?: number; hands_won?: number; chips_won?: number; gems_won?: number } } }
  | undefined;
if (legacyHello?.player_id !== "legacy_steam_player") throw new Error("legacy Steam identity should reuse existing internal player_id");
if (legacyHello.is_new_player !== false || legacyHello.profile_snapshot?.is_new_player !== false) throw new Error("legacy self-healing hello should not mark existing player as new");
if (legacyHello.profile_snapshot?.display_name !== "Legacy Before Bootstrap") throw new Error("legacy Steam hello must preserve historical display_name");
if (legacyHello.profile_snapshot.steam_persona_name !== "Legacy Luna" || legacyHello.profile_snapshot.steam_id !== "76561198000000007") throw new Error("legacy Steam hello should sync persona and preserve identity mapping");
if (legacyHello.profile_snapshot.wallet?.chips !== 4321 || legacyHello.profile_snapshot.wallet.gems !== 9) throw new Error("legacy bootstrap must not reset wallet");
if (legacyHello.profile_snapshot.progression?.total_xp !== 0 || legacyHello.profile_snapshot.progression.level !== 1 || legacyHello.profile_snapshot.progression.title_id !== "new_player") throw new Error("legacy hello should self-heal default progression");
if (legacyHello.profile_snapshot.statistics?.hands_played !== 0 || legacyHello.profile_snapshot.statistics.hands_won !== 0 || legacyHello.profile_snapshot.statistics.chips_won !== 0 || legacyHello.profile_snapshot.statistics.gems_won !== 0) throw new Error("legacy hello should self-heal default statistics");

db.prepare("UPDATE player_progression SET total_xp = 900, level = 10, title_id = 'sharp_caller' WHERE player_id = ?").run("legacy_steam_player");
db.prepare("UPDATE player_statistics SET hands_played = 20, hands_won = 8, chips_won = 3456, gems_won = 11 WHERE player_id = ?").run("legacy_steam_player");
const legacyRepeatMessages: unknown[] = [];
const legacyRepeatWs = { OPEN: 1, readyState: 1, send: (data: string) => legacyRepeatMessages.push(JSON.parse(data)) };
const legacyRepeatClient = manager.connect(legacyRepeatWs as any);
manager.handle(legacyRepeatClient.id, {
  type: "hello",
  auth_provider: "steam",
  external_id: "76561198000000007",
  name: "Legacy Luna Again",
});
const legacyRepeatHello = legacyRepeatMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "hello") as
  | { player_id?: string; profile_snapshot?: { progression?: { total_xp?: number; level?: number; title_id?: string }; statistics?: { hands_played?: number; hands_won?: number; chips_won?: number; gems_won?: number } } }
  | undefined;
if (legacyRepeatHello?.player_id !== "legacy_steam_player") throw new Error("legacy repeat hello should keep same player_id");
if (legacyRepeatHello.profile_snapshot?.progression?.total_xp !== 900 || legacyRepeatHello.profile_snapshot.progression.level !== 10 || legacyRepeatHello.profile_snapshot.progression.title_id !== "sharp_caller") throw new Error("legacy repeat hello must not reset existing progression");
if (legacyRepeatHello.profile_snapshot.statistics?.hands_played !== 20 || legacyRepeatHello.profile_snapshot.statistics.hands_won !== 8 || legacyRepeatHello.profile_snapshot.statistics.chips_won !== 3456 || legacyRepeatHello.profile_snapshot.statistics.gems_won !== 11) throw new Error("legacy repeat hello must not reset existing statistics");

const dailyCycleClient = manager.connect();
manager.handle(dailyCycleClient.id, { type: "hello", player_id: "daily_cycle_player", name: "Daily Cycle" });
const dailyCycleWalletRepository = new WalletRepository(db);
const dailyCycleBonusRepository = new LoginBonusRepository(db, dailyCycleWalletRepository);
const dailyCycleProfileRepository = new ProfileBootstrapRepository(db, dailyCycleBonusRepository);
dailyCycleBonusRepository.setProgressionRepository(dailyCycleProfileRepository);
const expectedDailyRewards = [
  { chips: 1000, xp: 25, gems: 0 },
  { chips: 1250, xp: 25, gems: 0 },
  { chips: 1500, xp: 25, gems: 0 },
  { chips: 2000, xp: 25, gems: 0 },
  { chips: 2500, xp: 25, gems: 0 },
  { chips: 3000, xp: 25, gems: 0 },
  { chips: 6000, xp: 50, gems: 100 },
];
let expectedCycleChips = STARTER_CHIPS;
let expectedCycleGems = STARTER_GEMS;
let expectedCycleXp = 0;
for (let index = 0; index < expectedDailyRewards.length; index += 1) {
  const reward = expectedDailyRewards[index];
  const result = dailyCycleBonusRepository.claimToday("daily_cycle_player", new Date(`2026-07-0${index + 1}T12:00:00.000Z`));
  expectedCycleChips += reward.chips;
  expectedCycleGems += reward.gems;
  expectedCycleXp += reward.xp;
  if (!result.daily_login_awarded || result.reward_day !== index + 1) throw new Error("daily bonus cycle should award each day in order");
  if (result.awarded_chips !== reward.chips || result.awarded_xp !== reward.xp || result.awarded_gems !== reward.gems) throw new Error("daily bonus reward table should match starter economy");
}
const dailyCycleWallet = db.prepare("SELECT chips, gems FROM wallets WHERE player_id = ?").get("daily_cycle_player") as { chips: number; gems: number };
const dailyCycleProgression = db.prepare("SELECT total_xp, level FROM player_progression WHERE player_id = ?").get("daily_cycle_player") as { total_xp: number; level: number };
if (dailyCycleWallet.chips !== expectedCycleChips || dailyCycleWallet.gems !== expectedCycleGems) throw new Error("daily bonus cycle should grant balanced chips and Day 7 gems");
if (dailyCycleProgression.total_xp !== expectedCycleXp || dailyCycleProgression.level !== levelForTotalXp(expectedCycleXp)) throw new Error("daily bonus cycle should persist XP and derived level");

const walletHistoryMessages: any[] = [];
const walletHistoryWs = { OPEN: 1, readyState: 1, send: (payload: string) => walletHistoryMessages.push(JSON.parse(payload)) };
const walletHistoryClient = manager.connect(walletHistoryWs as any);
manager.handle(walletHistoryClient.id, { type: "hello", player_id: "wallet_history_owner", name: "Wallet History Owner" });
const walletHistoryRepository = new WalletRepository(db);
walletHistoryRepository.addChips("wallet_history_owner", 11, { reason: "daily_bonus", now: "2099-01-01T00:00:01.000Z" });
walletHistoryRepository.addGems("wallet_history_owner", 22, { reason: "official_replay_unlock", now: "2099-01-01T00:00:02.000Z" });
const walletHistoryOtherClient = manager.connect();
manager.handle(walletHistoryOtherClient.id, { type: "hello", player_id: "wallet_history_other", name: "Wallet History Other" });
walletHistoryRepository.addChips("wallet_history_other", 7777, { reason: "wallet_adjustment", now: "2099-01-01T00:00:03.000Z" });

manager.handle("wallet_history_owner", { type: "get_wallet_history", currency: "all", limit: 2, player_id: "wallet_history_other" });
const historyPageOne = walletHistoryMessages.filter((message) => message.type === "wallet_history").at(-1);
if (historyPageOne.wallet_history.length !== 2 || historyPageOne.wallet_history.some((entry: any) => entry.amount === 7777)) throw new Error("wallet history must be isolated to the authenticated player");
if (historyPageOne.wallet_history[0].amount !== 22 || historyPageOne.wallet_history[1].amount !== 11) throw new Error("wallet history should be newest first");
if (!historyPageOne.next_cursor) throw new Error("limited wallet history should return a pagination cursor");
if (historyPageOne.wallet_history[0].display_label !== "Official Replay Unlock") throw new Error("wallet history should return player-facing reason labels");

manager.handle("wallet_history_owner", { type: "get_wallet_history", currency: "all", limit: 2, before: historyPageOne.next_cursor });
const historyPageTwo = walletHistoryMessages.filter((message) => message.type === "wallet_history").at(-1);
if (historyPageTwo.wallet_history.some((entry: any) => historyPageOne.wallet_history.some((first: any) => first.transaction_id === entry.transaction_id))) throw new Error("wallet history cursor should not repeat rows");

manager.handle("wallet_history_owner", { type: "get_wallet_history", currency: "gems", limit: 50 });
const gemsHistory = walletHistoryMessages.filter((message) => message.type === "wallet_history").at(-1);
if (gemsHistory.wallet_history.length === 0 || gemsHistory.wallet_history.some((entry: any) => entry.currency !== "gems")) throw new Error("wallet history gems filter should only return gems");
manager.handle("wallet_history_owner", { type: "get_wallet_history", currency: "chips", limit: 50 });
const chipsHistory = walletHistoryMessages.filter((message) => message.type === "wallet_history").at(-1);
if (chipsHistory.wallet_history.length === 0 || chipsHistory.wallet_history.some((entry: any) => entry.currency !== "chips")) throw new Error("wallet history chips filter should only return chips");

console.log("DB_SMOKE_OK");
console.log(JSON.stringify({ db_path: process.env.TEXAS_DB_PATH, player_count: manager.adminSnapshot(false).player_count, total_wallet_chips: manager.adminSnapshot(false).total_wallet_chips }, null, 2));

function seatPlayer(playerId: string, name: string, roomId: string, seatIndex: number, ready = false): void {
  const client = manager.connect();
  manager.handle(client.id, { type: "hello", player_id: playerId, name });
  manager.handle(playerId, { type: "join_room", room_id: roomId });
  manager.handle(playerId, { type: "sit_down", room_id: roomId, seat_index: seatIndex });
  if (ready) manager.handle(playerId, { type: "ready", room_id: roomId, ready: true });
}

function expectThrows(expectedMessage: string, fn: () => void): void {
  try {
    fn();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message !== expectedMessage) throw new Error(`expected ${expectedMessage}, got ${message}`);
    return;
  }
  throw new Error(`expected ${expectedMessage}`);
}

function countRows(table: string, where = "1 = 1"): number {
  const row = db.prepare(`SELECT COUNT(*) AS count FROM ${table} WHERE ${where}`).get() as { count: number } | undefined;
  return Number(row?.count ?? 0);
}
