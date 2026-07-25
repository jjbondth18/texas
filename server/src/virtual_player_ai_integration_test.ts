import assert from "node:assert/strict";
import { legalActions } from "./betting_engine.js";
import { TableState } from "./table_state.js";
import { adaptVirtualBotDecision, mapVirtualPersonality } from "./virtual_player_decision_gateway.js";
import { buildVirtualBotContext } from "./virtual_player_context_builder.js";

function tableWithPlayers(count: number, botSeat: number): TableState {
  const table = new TableState("integration");
  for (let index = 0; index < count; index += 1) {
    table.sitDown({ id: index === botSeat ? "virtual:bot" : `human:${index}`, name: `P${index}`, connected: true }, index * 2, 2_000);
    table.setReady(index === botSeat ? "virtual:bot" : `human:${index}`, true);
  }
  table.startHand(1234, true);
  return table;
}

function context(table: TableState) {
  const bot = table.getSeatByPlayer("virtual:bot")!;
  table.currentTurnSeat = bot.seatIndex;
  return buildVirtualBotContext({
    botPlayerId: bot.playerId,
    table,
    seatCount: 6,
    legalActions: legalActions(table, bot.playerId),
    handIndex: 1,
    decisionIndex: 1,
    sessionSeed: "isolated-session",
  });
}

const headsUp = context(tableWithPlayers(2, 0));
assert.equal(headsUp.position, "button");
assert.equal(headsUp.activePlayerCount, 2);
const threeHanded = context(tableWithPlayers(3, 0));
assert.equal(threeHanded.position, "button");
const sparse = context(tableWithPlayers(3, 1));
assert.equal(sparse.seatCount, 6);

const allowed = ["botPlayerId","botHoleCards","communityCards","street","pot","currentBet","callAmount","minRaiseTo","maxRaiseTo","botStack","botCommittedThisStreet","bigBlind","smallBlind","seatCount","activePlayerCount","opponentsStillInHand","position","isInPosition","legalActions","publicActionHistory","handIndex","decisionIndex","sessionSeed"].sort();
assert.deepEqual(Object.keys(sparse).sort(), allowed);
for (const forbidden of ["deck","room","table","seats","playerMap","wallet","steamTicket","virtual","personality","internalReason"]) {
  assert.ok(!(forbidden in sparse));
}
const botCards = sparse.botHoleCards.map((card) => card.code);
assert.equal(botCards.length, 2);
for (const seat of sparse.botPlayerId ? [] : sparse.botHoleCards) void seat;

const foldedTable = tableWithPlayers(3, 1);
const foldedBot = foldedTable.getSeatByPlayer("virtual:bot")!;
foldedTable.seats.find((seat) => seat.playerId === "human:2")!.status = "folded";
foldedTable.currentTurnSeat = foldedBot.seatIndex;
assert.equal(context(foldedTable).opponentsStillInHand, 1);

assert.equal(mapVirtualPersonality({ skillProfile: "tight_passive" }), "safe");
assert.equal(mapVirtualPersonality({ skillProfile: "tight_aggressive" }), "active");
assert.equal(mapVirtualPersonality({ skillProfile: "loose_passive" }), "balanced");
assert.equal(mapVirtualPersonality({ skillProfile: "unknown" as "balanced" }), "balanced");
const noBet = { ...sparse, currentBet: 0 };
assert.equal(adaptVirtualBotDecision(noBet, { action: "raise", raiseTo: 100, internalReason: "preflop_value", internalStrength: .8 }, "balanced").action, "bet");
const facing = { ...sparse, currentBet: 50 };
const raised = adaptVirtualBotDecision(facing, { action: "raise", raiseTo: 150, internalReason: "preflop_value", internalStrength: .8 }, "balanced");
assert.equal(raised.action, "raise");
assert.equal(raised.amount, 150);
assert.equal(adaptVirtualBotDecision(facing, { action: "all_in", internalReason: "preflop_value", internalStrength: .8 }, "active").action, "all_in");
console.log("virtual AI integration tests passed");
