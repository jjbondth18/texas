import assert from "node:assert/strict";
import { RoomManager } from "./room_manager.js";
import { CHALLENGE_SESSION_CONFIGS, challengeCatalog, challengePayout } from "./ai_challenge/ai_challenge_config.js";
import type { ChallengeId } from "./ai_challenge/ai_challenge_types.js";

class FakeWs {
  OPEN = 1;
  readyState = 1;
  sent: any[] = [];
  send(payload: string): void {
    this.sent.push(JSON.parse(payload));
  }
}

let nextId = 1;

function wallet(manager: RoomManager, playerId: string) {
  return (manager as any).wallets.get(playerId);
}

function createdRoomId(ws: FakeWs): string {
  return String(ws.sent.filter((message) => message.type === "ai_challenge_created").at(-1)?.room_id ?? "");
}

function setup(challengeId: ChallengeId, activate = true) {
  const manager = new RoomManager();
  const ws = new FakeWs();
  const connected = manager.connect(ws as any);
  const playerId = `challenge_economy_${challengeId}_${Date.now()}_${nextId++}`;
  manager.handle(connected.id, { type: "hello", player_id: playerId, name: "Economy Tester" });
  const before = wallet(manager, playerId);
  manager.handle(playerId, { type: "create_ai_challenge", challenge_id: challengeId });
  const roomId = createdRoomId(ws);
  const room = manager.getRoom(roomId) as any;
  assert(room, "challenge room should exist");
  if (activate) manager.handle(playerId, { type: "join_room", room_id: roomId });
  return { manager, ws, playerId, room, before };
}

function forceEnd(room: any, playerChips: number, botChips: number, handId: number): void {
  const playerSeat = room.table.getSeatByPlayer(room.challengePlayerId);
  const botSeat = room.table.getSeatByPlayer(room.challengeBotPlayerId);
  playerSeat.chips = playerChips;
  botSeat.chips = botChips;
  playerSeat.status = playerChips > 0 ? "ready" : "sit_out";
  botSeat.status = botChips > 0 ? "ready" : "sit_out";
  room.table.phase = "hand_over";
  room.table.handId = handId;
  room.table.currentTurnSeat = -1;
}

function lastResult(ws: FakeWs) {
  return ws.sent.filter((message) => message.type === "ai_challenge_result").at(-1);
}

assert.deepEqual(challengeCatalog().map((item) => item.challenge_id), ["rookie", "sharp", "boss"]);

for (const challengeId of ["rookie", "sharp", "boss"] as const) {
  const config = CHALLENGE_SESSION_CONFIGS[challengeId];
  assert.equal(challengePayout(config, "timeout_victory").walletPayoutChips, config.entryFeeChips * 1.5);
  assert.equal(challengePayout(config, "knockout_victory").walletPayoutChips, config.entryFeeChips * 2);
  assert.equal(challengePayout(config, "draw").walletPayoutChips, config.entryFeeChips);

  const { manager, playerId, room, before } = setup(challengeId);
  assert.equal(room.challengeId, challengeId);
  assert.equal(room.buyIn, config.startingStack);
  assert.equal(room.smallBlind, config.smallBlind);
  assert.equal(room.bigBlind, config.bigBlind);
  assert.equal(room.handCount, config.maxHands);
  assert.equal(wallet(manager, playerId).chips, before.chips - config.entryFeeChips, `${challengeId} should charge configured entry fee`);
  assert.equal(wallet(manager, playerId).gems, before.gems, `${challengeId} should not touch gems`);
  assert.equal((manager as any).wallets.transactionsForPlayer(playerId, 20).filter((item: any) => item.reason === "ai_challenge_entry").length, 1, `${challengeId} entry should be audited once`);
  const afterActivation = wallet(manager, playerId).chips;
  manager.handle(playerId, { type: "join_room", room_id: room.id });
  manager.handle(playerId, { type: "create_ai_challenge", challenge_id: challengeId });
  assert.equal(wallet(manager, playerId).chips, afterActivation, `${challengeId} repeated create/join must not charge twice`);
}

{
  const manager = new RoomManager();
  const client = manager.connect();
  const playerId = `challenge_invalid_${Date.now()}_${nextId++}`;
  manager.handle(client.id, { type: "hello", player_id: playerId, name: "Invalid" });
  assert.throws(() => manager.handle(playerId, { type: "create_ai_challenge", challenge_id: "legend" }), /invalid_challenge_id/);
}

{
  const manager = new RoomManager();
  const client = manager.connect();
  const playerId = `challenge_poor_${Date.now()}_${nextId++}`;
  manager.handle(client.id, { type: "hello", player_id: playerId, name: "No Chips" });
  (manager as any).wallets.deductChips(playerId, wallet(manager, playerId).chips, { reason: "test_empty_wallet" });
  assert.throws(() => manager.handle(playerId, { type: "create_ai_challenge", challenge_id: "boss" }), /insufficient_chips/);
}

for (const [challengeId, resultKind, playerChips, botChips, handId, expectedPayout] of [
  ["rookie", "timeout_victory", 1700, 300, 20, 300],
  ["rookie", "knockout_victory", 2000, 0, 4, 400],
  ["rookie", "draw", 1000, 1000, 20, 200],
  ["rookie", "defeat", 0, 2000, 4, 0],
  ["sharp", "timeout_victory", 2000, 1000, 25, 750],
  ["sharp", "knockout_victory", 3000, 0, 5, 1000],
  ["sharp", "draw", 1500, 1500, 25, 500],
  ["sharp", "defeat", 0, 3000, 5, 0],
  ["boss", "timeout_victory", 2800, 1200, 30, 1500],
  ["boss", "knockout_victory", 4000, 0, 6, 2000],
  ["boss", "draw", 2000, 2000, 30, 1000],
  ["boss", "defeat", 0, 4000, 6, 0],
] as const) {
  const config = CHALLENGE_SESSION_CONFIGS[challengeId];
  const { manager, ws, playerId, room, before } = setup(challengeId);
  forceEnd(room, playerChips, botChips, handId);
  (manager as any).updatePublicRoomProgress(room);
  const result = lastResult(ws);
  assert.equal(result?.settlement_result, resultKind, `${challengeId} settlement kind`);
  assert.equal(result?.wallet_payout_chips, expectedPayout, `${challengeId} payout`);
  assert.equal(result?.net_result_chips, expectedPayout - config.entryFeeChips, `${challengeId} net result`);
  assert.equal(wallet(manager, playerId).chips, before.chips - config.entryFeeChips + expectedPayout, `${challengeId} wallet final`);
  const rewardTransactions = (manager as any).wallets.transactionsForPlayer(playerId, 20).filter((item: any) => item.reason === "ai_challenge_reward");
  assert.equal(rewardTransactions.length, expectedPayout > 0 ? 1 : 0, `${challengeId} reward should be audited exactly once`);
  const afterFirst = wallet(manager, playerId).chips;
  (manager as any).updatePublicRoomProgress(room);
  (manager as any).sendChallengeResult(room);
  assert.equal(wallet(manager, playerId).chips, afterFirst, "repeated result should not pay twice");
}

{
  const { manager, playerId, room, before } = setup("rookie", false);
  manager.handle(playerId, { type: "cash_out", room_id: room.id });
  assert.equal(wallet(manager, playerId).chips, before.chips, "prestart leave should refund entry fee");
  manager.disconnect(playerId);
  assert.equal(wallet(manager, playerId).chips, before.chips, "cleanup after refund should not refund twice");
}

{
  const { manager, playerId, room, before } = setup("rookie");
  manager.handle(playerId, { type: "cash_out", room_id: room.id });
  assert.equal(wallet(manager, playerId).chips, before.chips - CHALLENGE_SESSION_CONFIGS.rookie.entryFeeChips, "post-start leave should not refund entry fee");
  assert.equal(room.settlementResult, "defeat", "post-start leave should settle as defeat");
}

{
  const { manager, playerId, room, before } = setup("rookie");
  forceEnd(room, 2000, 0, 4);
  (manager as any).updatePublicRoomProgress(room);
  manager.handle(playerId, { type: "restart_session", room_id: room.id });
  assert.equal(wallet(manager, playerId).chips, before.chips - 200 + 400 - 200, "Play Again should charge a new entry fee");
  assert.equal((manager as any).wallets.transactionsForPlayer(playerId, 20).filter((item: any) => item.reason === "ai_challenge_entry").length, 2, "Play Again should create a second entry transaction");
  assert.equal(room.settlementApplied, false, "Play Again should clear old settlement state");
}

console.log("AI challenge economy tests passed.");
