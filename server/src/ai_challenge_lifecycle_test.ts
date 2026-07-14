import assert from "node:assert/strict";
import { legalActions } from "./betting_engine.js";
import { RoomManager } from "./room_manager.js";

class FakeWs {
  OPEN = 1;
  readyState = 1;
  sent: any[] = [];
  send(payload: string): void {
    this.sent.push(JSON.parse(payload));
  }
}

type TestSetup = {
  manager: RoomManager;
  ws: FakeWs;
  playerId: string;
  room: any;
};

let nextId = 1;

function setupChallenge(): TestSetup {
  const manager = new RoomManager();
  const ws = new FakeWs();
  const connected = manager.connect(ws as any);
  const playerId = `challenge_lifecycle_${Date.now()}_${nextId++}`;
  manager.handle(connected.id, { type: "hello", player_id: playerId, name: "Lifecycle Tester" });
  manager.handle(playerId, { type: "create_ai_challenge" });
  const roomId = manager.getClient(playerId)?.roomId ?? "";
  manager.handle(playerId, { type: "sit_down", room_id: roomId, seat_index: 5, buy_in: 1000 });
  const room = manager.getRoom(roomId) as any;
  assert(room, "challenge room should exist");
  return { manager, ws, playerId, room };
}

function forceChallengeEnd(room: any, playerChips: number, botChips: number, handId = 20): void {
  const playerSeat = room.table.getSeatByPlayer(room.challengePlayerId);
  const botSeat = room.table.getSeatByPlayer(room.challengeBotPlayerId);
  playerSeat.chips = playerChips;
  botSeat.chips = botChips;
  playerSeat.status = playerChips > 0 ? "ready" : "sit_out";
  botSeat.status = botChips > 0 ? "ready" : "sit_out";
  playerSeat.ready = playerChips > 0;
  botSeat.ready = botChips > 0;
  room.table.phase = "hand_over";
  room.table.handId = handId;
  room.table.currentTurnSeat = -1;
}

function resultMessages(ws: FakeWs): any[] {
  return ws.sent.filter((message) => message.type === "ai_challenge_result");
}

{
  const { manager, ws, room } = setupChallenge();
  forceChallengeEnd(room, 0, 2000, 4);
  (manager as any).updatePublicRoomProgress(room);
  assert.equal(room.sessionComplete, true, "player zero stack should complete challenge");
  assert.equal(resultMessages(ws).at(-1)?.result, "defeat", "player zero stack should be defeat");
}

{
  const { manager, ws, room } = setupChallenge();
  forceChallengeEnd(room, 2000, 0, 4);
  (manager as any).updatePublicRoomProgress(room);
  assert.equal(room.sessionComplete, true, "bot zero stack should complete challenge");
  assert.equal(resultMessages(ws).at(-1)?.result, "victory", "bot zero stack should be victory");
}

for (const [playerChips, botChips, expected] of [
  [1400, 600, "victory"],
  [600, 1400, "defeat"],
  [1000, 1000, "draw"],
] as const) {
  const { manager, ws, room } = setupChallenge();
  forceChallengeEnd(room, playerChips, botChips, 20);
  (manager as any).updatePublicRoomProgress(room);
  assert.equal(room.sessionComplete, true, "20th hand should complete challenge");
  assert.equal(room.table.phase, "session_complete", "completed challenge should enter session_complete");
  assert.equal(room.table.handId, 20, "20th hand should not become hand 21");
  const result = resultMessages(ws).at(-1);
  assert.equal(result?.result, expected, `20-hand result should be ${expected}`);
  assert.equal(result?.hands_played, 20, "hands_played should be exactly 20");
  (manager as any).updatePublicRoomProgress(room);
  (manager as any).broadcast(room);
  assert.equal(resultMessages(ws).length, 1, "result should be sent once");
  assert.equal(room.table.handId, 20, "completed challenge should not auto-start another hand");
}

{
  const { manager, room } = setupChallenge();
  forceChallengeEnd(room, 1000, 1000, 1);
  (manager as any).updatePublicRoomProgress(room);
  assert.equal(room.sessionComplete, false, "early split/equal stacks should not be challenge draw");
  assert.equal(room.table.handId, 2, "early split/equal stacks should continue to next hand");
}

{
  const { manager, ws, playerId, room } = setupChallenge();
  forceChallengeEnd(room, 2000, 0, 4);
  (manager as any).updatePublicRoomProgress(room);
  assert.equal(room.sessionComplete, true, "challenge should complete before Play Again");
  manager.handle(playerId, { type: "restart_session", room_id: room.id });
  const playerSeat = room.table.getSeatByPlayer(room.challengePlayerId);
  const botSeat = room.table.getSeatByPlayer(room.challengeBotPlayerId);
  assert.equal(room.sessionComplete, false, "Play Again should reopen the challenge session");
  assert.equal(room.challengeResultSent, false, "Play Again should reset result delivery guard");
  assert.equal(room.table.handId, 1, "Play Again should restart from hand 1");
  assert.equal((playerSeat?.chips ?? 0) + (botSeat?.chips ?? 0) + room.table.totalPot(), 2000, "Play Again should reset table chips before posting blinds");
  assert.equal(room.table.totalPot(), 30, "Play Again should immediately post challenge blinds for the new hand");
  assert.equal(resultMessages(ws).length, 1, "Play Again should not resend the old result");
}

{
  const { manager, room } = setupChallenge();
  const botSeat = room.table.getSeatByPlayer(room.challengeBotPlayerId);
  room.table.currentTurnSeat = botSeat.seatIndex;
  (manager as any).scheduleChallengeBotIfNeeded(room);
  const firstTimer = room.challengeBotTimer;
  (manager as any).scheduleChallengeBotIfNeeded(room);
  assert(firstTimer, "bot turn should schedule one timer");
  assert.equal(room.challengeBotTimer, firstTimer, "duplicate schedule should not create a second timer");
  (manager as any).clearChallengeBotTimer(room);
}

{
  const { manager, room } = setupChallenge();
  const playerSeat = room.table.getSeatByPlayer(room.challengePlayerId);
  room.table.currentTurnSeat = playerSeat.seatIndex;
  (manager as any).scheduleChallengeBotIfNeeded(room);
  assert.equal(room.challengeBotTimer, undefined, "non-bot turn should not schedule Challenge policy");
}

{
  const manager = new RoomManager();
  const ordinaryRoom = (manager as any).createRoom();
  ordinaryRoom.table.phase = "preflop";
  ordinaryRoom.table.currentTurnSeat = 5;
  (manager as any).scheduleChallengeBotIfNeeded(ordinaryRoom);
  assert.equal(ordinaryRoom.challengeBotTimer, undefined, "ordinary rooms should not schedule Challenge bot");
}

{
  const { manager, playerId, room } = setupChallenge();
  const before = manager.adminSnapshot(false);
  assert.throws(() => manager.handle(playerId, { type: "add_table_chips", room_id: room.id, amount: 100 }), /cannot_add_chips_during_hand/, "Challenge should reject Add Chips");
  forceChallengeEnd(room, 2000, 0, 4);
  (manager as any).updatePublicRoomProgress(room);
  manager.handle(playerId, { type: "cash_out", room_id: room.id });
  const after = manager.adminSnapshot(false);
  assert.equal(after.total_wallet_chips, before.total_wallet_chips, "full Challenge lifecycle should not change wallet chips");
  assert.equal(after.total_wallet_gems, before.total_wallet_gems, "full Challenge lifecycle should not change gems");
}

{
  const { manager, room } = setupChallenge();
  const botSeat = room.table.getSeatByPlayer(room.challengeBotPlayerId);
  const context = (manager as any).challengeBotContext(room, botSeat, legalActions(room.table, room.challengeBotPlayerId));
  const forbidden = ["playerHoleCards", "deck", "deckOrder", "futureBoard", "privateSnapshots", "privateCards", "fullTableState", "roomState", "player"];
  for (const key of forbidden) assert(!Object.keys(context).includes(key), `context must not expose ${key}`);
  for (const action of context.visibleActionHistory) {
    const keys = Object.keys(action);
    assert(!keys.includes("holeCards") && !keys.includes("hole_cards") && !keys.includes("deck"), "visible action history must not include private card data");
  }
}

{
  const { manager, playerId, room } = setupChallenge();
  const botSeat = room.table.getSeatByPlayer(room.challengeBotPlayerId);
  room.table.currentTurnSeat = botSeat.seatIndex;
  (manager as any).scheduleChallengeBotIfNeeded(room);
  assert(room.challengeBotTimer, "bot timer should be pending before leave");
  manager.handle(playerId, { type: "cash_out", room_id: room.id });
  assert.equal(room.challengeBotTimer, undefined, "leaving Challenge should clear pending bot timer");
}

{
  const { manager, playerId, room } = setupChallenge();
  const botSeat = room.table.getSeatByPlayer(room.challengeBotPlayerId);
  room.table.currentTurnSeat = botSeat.seatIndex;
  (manager as any).scheduleChallengeBotIfNeeded(room);
  assert(room.challengeBotTimer, "bot timer should be pending before disconnect");
  manager.disconnect(playerId);
  assert.equal(room.challengeBotTimer, undefined, "disconnect should clear pending bot timer");
  assert.equal(room.table.getSeatByPlayer(playerId), undefined, "disconnect should remove challenge player seat");
}

{
  const { manager, ws, room } = setupChallenge();
  forceChallengeEnd(room, 2000, 0, 4);
  (manager as any).updatePublicRoomProgress(room);
  const actionCount = room.table.handActions.length;
  await new Promise((resolve) => setTimeout(resolve, 450));
  assert.equal(room.table.handActions.length, actionCount, "completed Challenge should not receive delayed bot actions");
  assert.equal(resultMessages(ws).length, 1, "completed Challenge should not emit another result after delay");
}

console.log("AI challenge lifecycle tests passed.");
