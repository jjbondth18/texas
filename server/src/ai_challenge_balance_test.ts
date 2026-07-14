import assert from "node:assert/strict";
import { applyPlayerAction, legalActions } from "./betting_engine.js";
import { TableState, type Seat } from "./table_state.js";
import { analyzeMadeHandAndDraws, seedFromParts, seededRandom } from "./ai_challenge/ai_challenge_equity.js";
import { buildChallengeContextForTest, classifyStartingHand, decideChallengeBotAction, ruleFallbackEquity } from "./ai_challenge/ai_challenge_policy.js";
import { CHALLENGE_SESSION_CONFIGS, challengePayout } from "./ai_challenge/ai_challenge_config.js";
import type { ChallengeBotContext, ChallengeId, ChallengeSettlementResult } from "./ai_challenge/ai_challenge_types.js";
import type { PlayerActionType, PrivateSnapshot } from "./protocol.js";

const MATCHES_PER_DIFFICULTY = 500;
const PLAYER_ID = "basic_rule_player";
const BOT_ID = "challenge_rule_bot";
const BASE_SEED = 0x5eed2026;

type MatchResult = Exclude<ChallengeSettlementResult, "prestart_cancelled">;

type BalanceRow = {
  difficulty: ChallengeId;
  matches: number;
  knockoutVictories: number;
  timeoutVictories: number;
  defeats: number;
  draws: number;
  totalHands: number;
  totalNetChips: number;
};

function simulateMatch(difficulty: ChallengeId, matchIndex: number): { result: MatchResult; hands: number; invalidActions: number } {
  const config = CHALLENGE_SESSION_CONFIGS[difficulty];
  const table = new TableState(`balance_${difficulty}_${matchIndex}`);
  table.smallBlind = config.smallBlind;
  table.bigBlind = config.bigBlind;
  table.sitDown({ id: PLAYER_ID, name: "Basic Rule Player", connected: true }, 5, config.startingStack);
  table.sitDown({ id: BOT_ID, name: `${config.displayName} Rule Bot`, connected: true, isAi: true }, 8, config.startingStack);
  const sessionSeed = seedFromParts(BASE_SEED, difficulty, matchIndex);
  let decisionIndex = 0;
  let invalidActions = 0;

  while (table.handId < config.maxHands) {
    const player = table.getSeatByPlayer(PLAYER_ID)!;
    const bot = table.getSeatByPlayer(BOT_ID)!;
    if (player.chips <= 0 || bot.chips <= 0) break;
    table.startHand(seedFromParts(sessionSeed, table.handId + 1), false);
    let actionGuard = 0;
    while (table.phase !== "hand_over") {
      actionGuard += 1;
      assert(actionGuard <= 100, `action loop exceeded guard for ${difficulty} match ${matchIndex}`);
      const actingSeat = table.getSeat(table.currentTurnSeat);
      assert(actingSeat, "active hand must have an acting seat");
      const legal = legalActions(table, actingSeat.playerId);
      assert(legal.length > 0, "acting player must have legal actions");
      decisionIndex += 1;
      const context = contextFor(table, actingSeat, legal, sessionSeed, decisionIndex, config.bot);
      const decision = actingSeat.playerId === BOT_ID
        ? decideChallengeBotAction(context)
        : decideBasicRulePlayerAction(context, config.bigBlind);
      try {
        applyPlayerAction(table, actingSeat.playerId, decision.action, decision.amount ?? 0);
      } catch {
        invalidActions += 1;
        const fallback: PlayerActionType = legal.some((item) => item.action === "check") ? "check" : "fold";
        applyPlayerAction(table, actingSeat.playerId, fallback);
      }
    }
    assert.equal(table.getSeatByPlayer(PLAYER_ID)!.chips + table.getSeatByPlayer(BOT_ID)!.chips, config.startingStack * 2, "simulated table chips must be conserved");
  }

  const playerChips = table.getSeatByPlayer(PLAYER_ID)!.chips;
  const botChips = table.getSeatByPlayer(BOT_ID)!.chips;
  const result: MatchResult = playerChips <= 0
    ? "defeat"
    : botChips <= 0
      ? "knockout_victory"
      : playerChips > botChips
        ? "timeout_victory"
        : playerChips < botChips
          ? "defeat"
          : "draw";
  return { result, hands: table.handId, invalidActions };
}

function contextFor(
  table: TableState,
  seat: Seat,
  legal: PrivateSnapshot["legal_actions"],
  sessionSeed: number,
  decisionIndex: number,
  tuning: ChallengeBotContext["botTuning"],
): ChallengeBotContext {
  const opponent = table.seats.find((candidate) => candidate.playerId && candidate.playerId !== seat.playerId)!;
  const call = legal.find((action) => action.action === "call");
  const raise = legal.find((action) => action.action === "raise" || action.action === "bet");
  return buildChallengeContextForTest({
    botHoleCards: seat.holeCards.slice(),
    communityCards: table.communityCards.slice(),
    street: table.phase as ChallengeBotContext["street"],
    pot: table.totalPot(),
    callAmount: Math.max(0, Number(call?.amount ?? table.currentBet - seat.currentBet)),
    minRaiseTo: Number.isFinite(raise?.min_amount) ? Number(raise?.min_amount) : null,
    maxRaiseTo: Number.isFinite(raise?.max_amount) ? Number(raise?.max_amount) : null,
    botStack: seat.chips,
    playerStack: opponent.chips,
    buttonSeat: table.dealerSeat,
    botSeat: seat.seatIndex,
    legalActions: legal.map((action) => action.action),
    visibleActionHistory: table.handActions.map((action) => ({ ...action })),
    handIndex: table.handId,
    decisionIndex,
    sessionSeed,
    botTuning: tuning ? { ...tuning, timeBudgetMs: 60_000 } : tuning,
  });
}

function decideBasicRulePlayerAction(context: ChallengeBotContext, bigBlind: number): { action: PlayerActionType; amount?: number } {
  const rng = seededRandom(seedFromParts(context.sessionSeed, "basic", context.handIndex, context.decisionIndex, context.botSeat));
  const canCheck = context.legalActions.includes("check");
  const canRaise = context.legalActions.includes("raise") || context.legalActions.includes("bet");
  if (context.street === "preflop") {
    const tier = classifyStartingHand(context.botHoleCards);
    const callBigBlinds = context.callAmount / Math.max(1, bigBlind);
    if (tier === "PREMIUM" || tier === "STRONG") {
      if (canRaise && rng() < 0.35) return sizedRaise(context, 0.5);
      return { action: canCheck ? "check" : "call" };
    }
    if (canCheck) return { action: "check" };
    if (tier === "PLAYABLE" && callBigBlinds <= 2) return { action: "call" };
    if (tier === "MARGINAL" && callBigBlinds <= 1 && rng() < 0.5) return { action: "call" };
    return { action: "fold" };
  }

  const info = analyzeMadeHandAndDraws(context.botHoleCards, context.communityCards);
  const equity = ruleFallbackEquity(context, info);
  const required = context.callAmount > 0 ? context.callAmount / Math.max(1, context.pot + context.callAmount) : 0;
  const strongDraw = info.flushDraw || info.openEndedStraightDraw || info.pairPlusDraw;
  if (canCheck) {
    if (canRaise && equity >= 0.68 && rng() < 0.55) return sizedRaise(context, 0.5);
    return { action: "check" };
  }
  if (info.category >= 2 && canRaise && equity >= required + 0.30 && rng() < 0.25) return sizedRaise(context, 0.5);
  if (equity >= required + 0.12) return { action: "call" };
  if (strongDraw && context.callAmount <= context.pot * 0.35 && rng() < 0.65) return { action: "call" };
  return { action: "fold" };
}

function sizedRaise(context: ChallengeBotContext, fraction: number): { action: PlayerActionType; amount: number } {
  const action: PlayerActionType = context.legalActions.includes("bet") ? "bet" : "raise";
  const raw = context.callAmount + Math.floor(Math.max(20, context.pot * fraction));
  return { action, amount: Math.max(context.minRaiseTo ?? raw, Math.min(context.maxRaiseTo ?? context.botStack, raw)) };
}

function runDifficulty(difficulty: ChallengeId): BalanceRow {
  const row: BalanceRow = { difficulty, matches: MATCHES_PER_DIFFICULTY, knockoutVictories: 0, timeoutVictories: 0, defeats: 0, draws: 0, totalHands: 0, totalNetChips: 0 };
  let invalidActions = 0;
  for (let match = 0; match < MATCHES_PER_DIFFICULTY; match += 1) {
    const simulated = simulateMatch(difficulty, match);
    row.totalHands += simulated.hands;
    invalidActions += simulated.invalidActions;
    if (simulated.result === "knockout_victory") row.knockoutVictories += 1;
    else if (simulated.result === "timeout_victory") row.timeoutVictories += 1;
    else if (simulated.result === "defeat") row.defeats += 1;
    else row.draws += 1;
    row.totalNetChips += challengePayout(CHALLENGE_SESSION_CONFIGS[difficulty], simulated.result).netResultChips;
  }
  assert.equal(row.knockoutVictories + row.timeoutVictories + row.defeats + row.draws, row.matches);
  assert.equal(invalidActions, 0, `${difficulty} simulation must not rely on invalid-action fallbacks`);
  return row;
}

for (const difficulty of ["rookie", "sharp", "boss"] as const) {
  assert.deepEqual(simulateMatch(difficulty, -1), simulateMatch(difficulty, -1), `${difficulty} simulation must reproduce with a fixed seed`);
}
const rows = (["rookie", "sharp", "boss"] as const).map(runDifficulty);
console.log(`AI Challenge balance simulation: basic_rule_player, seed=${BASE_SEED}, ${MATCHES_PER_DIFFICULTY} matches per difficulty`);
for (const row of rows) {
  const pct = (count: number) => `${(count * 100 / row.matches).toFixed(1)}%`;
  const victories = row.knockoutVictories + row.timeoutVictories;
  console.log([
    row.difficulty,
    `victory=${pct(victories)}`,
    `knockout=${pct(row.knockoutVictories)}`,
    `timeout=${pct(row.timeoutVictories)}`,
    `defeat=${pct(row.defeats)}`,
    `draw=${pct(row.draws)}`,
    `avgHands=${(row.totalHands / row.matches).toFixed(2)}`,
    `avgNetChips=${(row.totalNetChips / row.matches).toFixed(2)}`,
    `totalChipProduction=${row.totalNetChips}`,
  ].join(" "));
}
console.log("AI challenge balance simulation passed.");
