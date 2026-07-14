import assert from "node:assert/strict";
import { RoomManager } from "./room_manager.js";

const manager = new RoomManager();
const client = manager.connect();
manager.handle(client.id, { type: "hello", player_id: "challenge_smoke_player", name: "Smoke Tester" });
const beforeSnapshot = manager.adminSnapshot(false);
manager.handle("challenge_smoke_player", { type: "create_ai_challenge" });
const roomId = manager.getClient("challenge_smoke_player")?.roomId ?? "";
assert(roomId !== "", "challenge should assign the player to a room");
manager.handle("challenge_smoke_player", { type: "sit_down", room_id: roomId, seat_index: 5, buy_in: 1000 });
const room = manager.getRoom(roomId);
assert(room, "challenge room should exist");
assert.equal(room.table.smallBlind, 10);
assert.equal(room.table.bigBlind, 20);
assert.equal(room.table.handId, 1, "challenge should auto-start the first hand");
assert.equal(room.table.seats.filter((seat) => seat.playerId !== "").length, 2, "challenge should seat player and bot");
assert(room.table.seats.some((seat) => seat.playerId.startsWith("challenge_bot_") && seat.isAi), "challenge bot seat should be server-controlled AI");
const afterSnapshot = manager.adminSnapshot(false);
assert.equal(afterSnapshot.total_wallet_chips, beforeSnapshot.total_wallet_chips, "challenge should not change total wallet chips");
assert.equal(afterSnapshot.total_wallet_gems, beforeSnapshot.total_wallet_gems, "challenge should not change total wallet gems");

console.log("AI challenge room smoke test passed.");
