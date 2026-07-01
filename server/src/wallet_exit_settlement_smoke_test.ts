import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { RoomManager } from "./room_manager.js";

process.env.TEXAS_DB_PATH = join(mkdtempSync(join(tmpdir(), "texas-wallet-exit-smoke-")), "texas_dev.sqlite");

const manager = new RoomManager();

function hello(playerId: string, name: string) {
  const client = manager.connect();
  manager.handle(client.id, { type: "hello", player_id: playerId, name });
  return manager.getClient(playerId)!;
}

const host = hello("exit_smoke_host", "Exit Smoke Host");
const preHandRoom = manager.createRoom({ buyIn: 5000, smallBlind: 25, bigBlind: 50 });
manager.handle(host.id, { type: "join_room", room_id: preHandRoom.id });
manager.handle(host.id, { type: "sit_down", room_id: preHandRoom.id, seat_index: 5 });
manager.handle(host.id, { type: "cash_out", room_id: preHandRoom.id });
if (manager.walletAudit(host.id).unmatchedBuyIns.length !== 0) throw new Error("pre-hand exit should match buy-in with a refund");
const preHandWalletAfter = Number(manager.adminSnapshot(false).total_wallet_chips);
manager.handle(host.id, { type: "cash_out", room_id: preHandRoom.id });
if (Number(manager.adminSnapshot(false).total_wallet_chips) !== preHandWalletAfter) throw new Error("repeat pre-hand exit should not double refund");

const playerA = hello("exit_smoke_a", "Exit Smoke A");
const playerB = hello("exit_smoke_b", "Exit Smoke B");
const activeRoom = manager.createRoom({ buyIn: 5000, smallBlind: 25, bigBlind: 50, isPublic: false });
manager.handle(playerA.id, { type: "join_room", room_id: activeRoom.id });
manager.handle(playerA.id, { type: "sit_down", room_id: activeRoom.id, seat_index: 5 });
manager.handle(playerA.id, { type: "ready", room_id: activeRoom.id, ready: true });
manager.handle(playerB.id, { type: "join_room", room_id: activeRoom.id });
manager.handle(playerB.id, { type: "sit_down", room_id: activeRoom.id, seat_index: 8 });
manager.handle(playerB.id, { type: "ready", room_id: activeRoom.id, ready: true });
manager.handle(playerA.id, { type: "start_hand", room_id: activeRoom.id });
const remainingStack = activeRoom.table.getSeat(5)?.chips ?? 0;
const walletBefore = Number(manager.adminSnapshot(false).total_wallet_chips);
manager.handle(playerA.id, { type: "cash_out", room_id: activeRoom.id });
const walletAfter = Number(manager.adminSnapshot(false).total_wallet_chips);
if (walletAfter !== walletBefore + remainingStack) throw new Error("active hand exit should cash out only remaining stack");
if (manager.walletAudit(playerA.id).unmatchedBuyIns.length !== 0) throw new Error("active hand exit should match buy-in with table_cash_out");

console.log("Wallet exit settlement smoke test passed.");
