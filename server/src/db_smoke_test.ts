import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { RoomManager } from "./room_manager.js";
import { getDatabase } from "./db/database.js";
import { initializeSchema } from "./db/schema.js";

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
if (countRows("wallet_transactions", "reason = 'table_cash_out' AND amount = 5500") !== 1) throw new Error("cash out should write positive wallet transaction");
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
const steamClient = manager.connect();
manager.handle(steamClient.id, { type: "hello", auth_provider: "steam", external_id: "steam_76561198000000000", name: "Steam Smoke" });
if (countRows("player_identities", "provider = 'steam' AND external_id = 'steam_76561198000000000'") !== 1) throw new Error("steam provider should create identity");
if (manager.getClient("steam_76561198000000000")) throw new Error("server player_id should not directly equal Steam external_id");
expectThrows("invalid_identity_provider", () => manager.handle(manager.connect().id, { type: "hello", auth_provider: "email", external_id: "bad", name: "Bad Provider" }));
expectThrows("external_id is required", () => manager.handle(manager.connect().id, { type: "hello", auth_provider: "steam", external_id: "", name: "Empty External" }));
if (countRows("wallet_transactions") < 7) throw new Error("admin db wallet_transactions query should be readable");
if (countRows("player_identities") < 5) throw new Error("admin db player_identities query should be readable");

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
