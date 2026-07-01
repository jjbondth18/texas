import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { RoomManager } from "./room_manager.js";
import { getDatabase } from "./db/database.js";
import { initializeSchema } from "./db/schema.js";
import { config } from "./config.js";

process.env.TEXAS_DB_PATH = join(mkdtempSync(join(tmpdir(), "texas-db-smoke-")), "texas_dev.sqlite");

const manager = new RoomManager();
const client = manager.connect();

manager.handle(client.id, { type: "hello", player_id: "db_smoke_player", name: "DB Smoke", avatar_id: "locked_avatar" });

const helloClient = manager.getClient("db_smoke_player");
if (!helloClient) throw new Error("hello did not migrate client to requested player_id");

const firstProfile = manager.adminSnapshot(false);
if (Number(firstProfile.player_count) !== 1) throw new Error("expected one player after hello");
if (Number(firstProfile.identity_count) !== 1) throw new Error("expected local_dev identity after hello");
if (Number(firstProfile.total_wallet_chips) !== 11000) throw new Error("expected 10000 initial chips plus 1000 daily login chips");
if (Number(firstProfile.avatar_unlock_count) !== 1) throw new Error("new player should unlock the default avatar");
const db = getDatabase();
initializeSchema(db);
if (countRows("schema_migrations") < 2) throw new Error("migrations should be recorded and re-runnable");
if (countRows("player_identities", "provider = 'local_dev' AND external_id = 'db_smoke_player'") !== 1) throw new Error("hello should write local_dev identity");
if (countRows("wallet_transactions", "reason = 'initial_grant' AND amount = 10000") !== 1) throw new Error("initial chips should write wallet transaction");
if (countRows("wallet_transactions", "reason = 'daily_login_bonus' AND amount = 1000") !== 1) throw new Error("daily login should write wallet transaction");

const repeatIdentityClient = manager.connect();
manager.handle(repeatIdentityClient.id, { type: "hello", auth_provider: "local_dev", external_id: "db_smoke_player", name: "DB Smoke Repeat" });
if (!manager.getClient("db_smoke_player")) throw new Error("same local_dev external_id should resolve to the same server player_id");

manager.handle("db_smoke_player", { type: "buy_avatar", avatar_id: "1_01" });
const afterAvatarBuy = manager.adminSnapshot(false);
if (Number(afterAvatarBuy.total_wallet_chips) !== 9500) throw new Error("buy_avatar should deduct chips from wallet");
if (Number(afterAvatarBuy.avatar_unlock_count) !== 2) throw new Error("buy_avatar should write avatar unlock");
if (countRows("wallet_transactions", "reason = 'avatar_purchase' AND amount = -1500") !== 1) throw new Error("avatar purchase should write negative wallet transaction");
expectThrows("already_unlocked", () => manager.handle("db_smoke_player", { type: "buy_avatar", avatar_id: "1_01" }));
expectThrows("insufficient_gems", () => manager.handle("db_smoke_player", { type: "buy_avatar", avatar_id: "1_03" }));
expectThrows("avatar_not_unlocked", () => manager.handle("db_smoke_player", { type: "select_avatar", avatar_id: "2_01" }));
manager.handle("db_smoke_player", { type: "select_avatar", avatar_id: "1_01" });
if (manager.getClient("db_smoke_player")?.avatarId !== "1_01") throw new Error("select_avatar should update selected profile avatar");

manager.handle("db_smoke_player", { type: "hello", player_id: "db_smoke_player", name: "DB Smoke", avatar_id: "default" });
const secondProfile = manager.adminSnapshot(false);
if (Number(secondProfile.player_count) !== 1) throw new Error("second hello should not create another player");
if (Number(secondProfile.total_wallet_chips) !== 9500) throw new Error("daily login should not award twice on the same day");

const room = manager.createRoom();
manager.handle("db_smoke_player", { type: "join_room", room_id: room.id });
manager.handle("db_smoke_player", { type: "sit_down", room_id: room.id, seat_index: 0, buy_in: 999999 });
const afterBuyIn = manager.adminSnapshot(false);
if (Number(afterBuyIn.total_wallet_chips) !== 4500) throw new Error("sit_down should deduct room buy-in from wallet");
if (room.table.getSeat(0)?.chips !== 5000) throw new Error("sit_down should put room buy-in table chips on the seat");
const creatorSeatSnapshot = room.table.publicSnapshot().seats[0];
if (!creatorSeatSnapshot.occupied) throw new Error("authoritative snapshot should mark creator seat occupied");
if (creatorSeatSnapshot.player_id !== "db_smoke_player") throw new Error("authoritative snapshot should include creator player_id");
if (creatorSeatSnapshot.player_name !== "DB Smoke") throw new Error("authoritative snapshot should include creator name");
if (creatorSeatSnapshot.avatar_id !== "default") throw new Error("authoritative snapshot should include creator avatar_id");
if (!creatorSeatSnapshot.connected) throw new Error("authoritative snapshot should mark creator connected");
if (creatorSeatSnapshot.is_ai) throw new Error("authoritative snapshot should not mark creator as AI");
if (creatorSeatSnapshot.table_stack !== 5000) throw new Error("authoritative snapshot should expose creator table_stack");
const roomAdminTable = (afterBuyIn.table_list as Array<Record<string, unknown>>).find((table) => table.room_id === room.id);
if (!roomAdminTable) throw new Error("created room should appear in public table list");
if (Number(roomAdminTable.current_players) !== 1) throw new Error("public table list should count one connected real creator");
if (Number(roomAdminTable.seated_count) !== 1) throw new Error("public table list should show creator as 1/6");
if (countRows("wallet_transactions", "reason = 'table_buy_in' AND amount = -5000") !== 1) throw new Error("table buy-in should write negative wallet transaction");

manager.handle("db_smoke_player", { type: "add_table_chips", room_id: room.id, amount: 500 });
const afterAdd = manager.adminSnapshot(false);
if (Number(afterAdd.total_wallet_chips) !== 4000) throw new Error("add_table_chips should deduct wallet chips");
if (room.table.getSeat(0)?.chips !== 5500) throw new Error("add_table_chips should increase table chips");
if (countRows("wallet_transactions", "reason = 'add_table_chips' AND amount = -500") !== 1) throw new Error("add_table_chips should write negative wallet transaction");

expectThrows("insufficient_chips", () => manager.handle("db_smoke_player", { type: "add_table_chips", room_id: room.id, amount: 999999 }));
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== 4000) throw new Error("failed add_table_chips should not change wallet");

manager.handle("db_smoke_player", { type: "cash_out", room_id: room.id });
const afterCashOut = manager.adminSnapshot(false);
if (Number(afterCashOut.total_wallet_chips) !== 9500) throw new Error("cash_out should refund remaining table chips");
if (room.table.getSeat(0)?.playerId !== "") throw new Error("cash_out should clear the seat");
if (countRows("wallet_transactions", "reason = 'left_before_official_hand' AND amount = 5500") !== 1) throw new Error("pre-hand cash out should write left_before_official_hand wallet transaction");
expectThrows("not_seated", () => manager.handle("db_smoke_player", { type: "cash_out", room_id: room.id }));
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== 9500) throw new Error("repeat cash_out should not double refund");

const handRoom = manager.createRoom();
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
expectThrows("cannot_cash_out_during_hand", () => manager.handle("db_smoke_player", { type: "cash_out", room_id: handRoom.id }));
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== beforeHandWalletTotal) throw new Error("active hand table chip operations should not change wallet");

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
expectThrows("invalid_table_config", () => manager.handle("db_smoke_config", { type: "create_table", buy_in: 12345, small_blind: 25, big_blind: 50, hand_count: 10 }));
expectThrows("invalid_table_config", () => manager.handle("db_smoke_config", { type: "create_table", buy_in: 10000, small_blind: 10, big_blind: 20, hand_count: 10 }));

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
if (readySnapshot?.snapshot?.room_state !== "ready_to_start" || readySnapshot.snapshot.table_state !== "ready_to_start") throw new Error("public room should enter ready_to_start after second real player joins");
if (readySnapshot.snapshot.host_player_id !== "ready_host") throw new Error("ready_to_start snapshot should include host player id");
expectThrows("not_host", () => manager.handle("ready_joiner", { type: "start_hand", room_id: readyRoom.id }));
manager.handle("ready_host", { type: "start_hand", room_id: readyRoom.id });
if (readyRoom.table.phase === "waiting") throw new Error("host should be able to start public hand from ready_to_start");
if (readyRoom.table.seats.filter((seat) => seat.isAi || seat.warmupAi).length !== 0) throw new Error("public hand should start with real players only");
const midJoiner = manager.connect();
manager.handle(midJoiner.id, { type: "hello", player_id: "mid_joiner", name: "Mid Joiner" });
manager.handle("mid_joiner", { type: "join_room", room_id: readyRoom.id });
manager.handle("mid_joiner", { type: "sit_down", room_id: readyRoom.id, seat_index: 2 });
const midSeat = readyRoom.table.getSeatByPlayer("mid_joiner");
if (!midSeat || midSeat.status !== "waiting_next_hand") throw new Error("mid-hand joiner should wait for next hand");
if (midSeat.holeCards.length !== 0) throw new Error("mid-hand joiner should not receive current hand hole cards");
if (readyRoom.table.currentTurnSeat === 2) throw new Error("mid-hand joiner should not enter current turn order");
readyRoom.table.phase = "hand_over";
readyRoom.table.currentTurnSeat = -1;
for (const seat of readyRoom.table.seats) {
  if (seat.status === "playing") seat.status = "sitting";
}
manager.handle("ready_host", { type: "start_hand", room_id: readyRoom.id });
const nextSeat = readyRoom.table.getSeatByPlayer("mid_joiner");
if (!nextSeat || nextSeat.status !== "playing" || nextSeat.holeCards.length !== 2) throw new Error("mid-hand joiner should receive cards on the next hand");
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
const beforeMockPurchase = manager.adminSnapshot(false);
manager.handle("mock_purchase_player", { type: "mock_purchase", currency: "chips", amount: 50000, source: "store_mock" });
manager.handle("mock_purchase_player", { type: "mock_purchase", currency: "gems", amount: 500, source: "store_mock" });
const afterMockPurchase = manager.adminSnapshot(false);
if (Number(afterMockPurchase.total_wallet_chips) !== Number(beforeMockPurchase.total_wallet_chips) + 50000) throw new Error("mock chip purchase should update server wallet");
if (Number(afterMockPurchase.total_wallet_gems) !== Number(beforeMockPurchase.total_wallet_gems) + 500) throw new Error("mock gem purchase should update server wallet");
if (countRows("wallet_transactions", "reason = 'store_mock_purchase' AND currency = 'chips' AND amount = 50000") !== 1) throw new Error("mock chip purchase should write wallet transaction");
if (countRows("wallet_transactions", "reason = 'store_mock_purchase' AND currency = 'gems' AND amount = 500") !== 1) throw new Error("mock gem purchase should write wallet transaction");
const purchaseResult = mockPurchaseMessages.find((message) => typeof message === "object" && message !== null && (message as { type?: string }).type === "mock_purchase_result") as
  | { type: string; ok?: boolean; currency?: string; amount?: number; wallet?: { chips?: number; gems?: number } }
  | undefined;
if (!purchaseResult || purchaseResult.ok !== true || purchaseResult.currency !== "chips" || Number(purchaseResult.wallet?.chips) < 50000) throw new Error("mock purchase should return result with synced wallet");
const affordableRoom = manager.createRoom({ buyIn: 20000, smallBlind: 50, bigBlind: 100, handCount: 10 });
manager.handle("mock_purchase_player", { type: "join_room", room_id: affordableRoom.id });
manager.handle("mock_purchase_player", { type: "sit_down", room_id: affordableRoom.id, seat_index: 0 });
if (!affordableRoom.table.publicSnapshot().seats[0].occupied) throw new Error("mock chip purchase should make selected buy-in affordable");
const beforeDisabledTotal = Number(manager.adminSnapshot(false).total_wallet_chips);
config.allowMockPurchases = false;
expectThrows("mock_purchase_disabled", () => manager.handle("mock_purchase_player", { type: "mock_purchase", currency: "chips", amount: 10000, source: "store_mock" }));
config.allowMockPurchases = true;
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== beforeDisabledTotal) throw new Error("disabled mock purchase should not change wallet");

console.log("DB_SMOKE_OK");
console.log(JSON.stringify({ db_path: process.env.TEXAS_DB_PATH, player_count: manager.adminSnapshot(false).player_count, total_wallet_chips: manager.adminSnapshot(false).total_wallet_chips }, null, 2));

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
