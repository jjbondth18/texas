import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { RoomManager } from "./room_manager.js";

process.env.TEXAS_DB_PATH = join(mkdtempSync(join(tmpdir(), "texas-db-smoke-")), "texas_dev.sqlite");

const manager = new RoomManager();
const client = manager.connect();

manager.handle(client.id, { type: "hello", player_id: "db_smoke_player", name: "DB Smoke", avatar_id: "locked_avatar" });

const helloClient = manager.getClient("db_smoke_player");
if (!helloClient) throw new Error("hello did not migrate client to requested player_id");

const firstProfile = manager.adminSnapshot(false);
if (Number(firstProfile.player_count) !== 1) throw new Error("expected one player after hello");
if (Number(firstProfile.total_wallet_chips) !== 11000) throw new Error("expected 10000 initial chips plus 1000 daily login chips");

manager.handle("db_smoke_player", { type: "hello", player_id: "db_smoke_player", name: "DB Smoke", avatar_id: "default" });
const secondProfile = manager.adminSnapshot(false);
if (Number(secondProfile.player_count) !== 1) throw new Error("second hello should not create another player");
if (Number(secondProfile.total_wallet_chips) !== 11000) throw new Error("daily login should not award twice on the same day");

const room = manager.createRoom();
manager.handle("db_smoke_player", { type: "join_room", room_id: room.id });
manager.handle("db_smoke_player", { type: "sit_down", room_id: room.id, seat_index: 0, buy_in: 1000 });
const afterBuyIn = manager.adminSnapshot(false);
if (Number(afterBuyIn.total_wallet_chips) !== 10000) throw new Error("sit_down should deduct buy-in from wallet");

console.log("DB_SMOKE_OK");
console.log(JSON.stringify({ db_path: process.env.TEXAS_DB_PATH, player_count: afterBuyIn.player_count, total_wallet_chips: afterBuyIn.total_wallet_chips }, null, 2));
