import assert from "node:assert/strict";
import { RoomManager } from "./room_manager.js";
import { CHALLENGE_SESSION_CONFIGS } from "./ai_challenge/ai_challenge_config.js";

class FakeWs {
  OPEN = 1;
  readyState = 1;
  sent: any[] = [];
  send(payload: string): void {
    this.sent.push(JSON.parse(payload));
  }
}

const manager = new RoomManager();
const ws = new FakeWs();
const client = manager.connect(ws as any);
manager.handle(client.id, { type: "hello", player_id: "challenge_smoke_player", name: "Smoke Tester" });
const beforeSnapshot = manager.adminSnapshot(false);
manager.handle("challenge_smoke_player", { type: "create_ai_challenge", challenge_id: "rookie" });
const created = ws.sent.filter((message) => message.type === "ai_challenge_created").at(-1);
const roomId = String(created?.room_id ?? "");
assert(roomId !== "", "challenge create should return a reserved room");
assert.equal(created?.already_seated, false, "challenge create should declare that the table connection must activate the reserved room");
assert.equal(created?.entry_fee_charged, true, "challenge create should declare that the entry fee was already charged");
manager.handle("challenge_smoke_player", { type: "join_room", room_id: roomId });
const room = manager.getRoom(roomId);
assert(room, "challenge room should exist");
assert.equal(room.table.smallBlind, 10);
assert.equal(room.table.bigBlind, 20);
assert.equal(room.table.handId, 1, "challenge should auto-start the first hand");
assert.equal(room.table.seats.filter((seat) => seat.playerId !== "").length, 2, "challenge should seat player and bot");
assert(room.table.seats.some((seat) => seat.playerId.startsWith("challenge_bot_") && seat.isAi), "challenge bot seat should be server-controlled AI");
const afterSnapshot = manager.adminSnapshot(false);
assert.equal(Number(afterSnapshot.total_wallet_chips), Number(beforeSnapshot.total_wallet_chips) - CHALLENGE_SESSION_CONFIGS.rookie.entryFeeChips, "challenge should charge the entry fee once");
assert.equal(afterSnapshot.total_wallet_gems, beforeSnapshot.total_wallet_gems, "challenge should not change total wallet gems");

console.log("AI challenge room smoke test passed.");
