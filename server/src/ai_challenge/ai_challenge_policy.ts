import type { Card, PlayerActionType, PrivateSnapshot } from "../protocol.js";
import { CHALLENGE_SESSION_CONFIG, STARTING_HAND_TIERS } from "./ai_challenge_config.js";
import { analyzeMadeHandAndDraws, estimatePostflopEquity, seedFromParts, seededRandom } from "./ai_challenge_equity.js";
import type { ChallengeBotContext, ChallengeBotDecision, StartingHandTier } from "./ai_challenge_types.js";

const RANK_ORDER = "23456789TJQKA";
const RANK_VALUE: Record<string, number> = Object.fromEntries([...RANK_ORDER].map((rank, index) => [rank, index + 2]));

export function decideChallengeBotAction(context: ChallengeBotContext): ChallengeBotDecision {
  const seed = seedFromParts(context.sessionSeed, context.handIndex, context.decisionIndex, context.botSeat);
  const rng = seededRandom(seed);
  const raw = context.street === "preflop" ? decidePreflop(context, rng) : decidePostflop(context, rng, seed);
  return normalizeDecision(context, raw);
}

export function buildChallengeContextForTest(input: Partial<ChallengeBotContext> = {}): ChallengeBotContext {
  return {
    botHoleCards: input.botHoleCards ?? [card("A", "S"), card("A", "H")],
    communityCards: input.communityCards ?? [],
    street: input.street ?? "preflop",
    pot: input.pot ?? 30,
    callAmount: input.callAmount ?? 10,
    minRaiseTo: input.minRaiseTo ?? 40,
    maxRaiseTo: input.maxRaiseTo ?? 1000,
    botStack: input.botStack ?? 980,
    playerStack: input.playerStack ?? 980,
    buttonSeat: input.buttonSeat ?? 5,
    botSeat: input.botSeat ?? 8,
    legalActions: input.legalActions ?? ["fold", "call", "raise", "all_in"],
    visibleActionHistory: input.visibleActionHistory ?? [],
    handIndex: input.handIndex ?? 1,
    decisionIndex: input.decisionIndex ?? 1,
    sessionSeed: input.sessionSeed ?? 12345,
    botTuning: input.botTuning ?? CHALLENGE_SESSION_CONFIG.bot,
  };
}

export function card(rank: Card["rank"], suit: Card["suit"]): Card {
  return { rank, suit, code: `${rank}${suit}` };
}

export function classifyStartingHand(cards: Card[]): StartingHandTier {
  const key = startingHandKey(cards);
  if (STARTING_HAND_TIERS.PREMIUM.includes(key)) return "PREMIUM";
  if (STARTING_HAND_TIERS.STRONG.includes(key)) return "STRONG";
  if (STARTING_HAND_TIERS.PLAYABLE.includes(key)) return "PLAYABLE";
  const [a, b] = sortedRanks(cards);
  const suited = cards[0].suit === cards[1].suit;
  const gap = Math.abs(RANK_VALUE[a] - RANK_VALUE[b]);
  if (suited && (a === "K" || a === "Q" || gap <= 2)) return "MARGINAL";
  if (RANK_VALUE[a] >= 12 && gap <= 4) return "MARGINAL";
  return "TRASH";
}

function decidePreflop(context: ChallengeBotContext, rng: () => number): ChallengeBotDecision {
  const tuning = context.botTuning ?? CHALLENGE_SESSION_CONFIG.bot;
  const tier = classifyStartingHand(context.botHoleCards);
  const bigBlind = Math.max(1, Math.floor(context.pot >= 60 ? context.pot / 3 : 20));
  const callBigBlinds = context.callAmount / bigBlind;
  const facingRaise = context.callAmount > bigBlind;
  const canCheck = context.legalActions.includes("check");
  const canRaise = context.legalActions.includes("raise") || context.legalActions.includes("bet");
  if (tier === "PREMIUM") {
    if (canRaise && rng() < tuning.raiseStrongFrequency) return raiseDecision(context, "preflop premium value", pickBetFraction(tuning, rng, true));
    return callOrCheck(context, "preflop premium trap");
  }
  if (tier === "STRONG") {
    if (facingRaise && callBigBlinds > 5 && rng() < 0.35 + tuning.decisionErrorRate) return foldDecision("strong hand facing oversized raise");
    if (canRaise && rng() < (facingRaise ? 0.30 : tuning.raiseStrongFrequency * 0.85)) return raiseDecision(context, "preflop strong pressure", pickBetFraction(tuning, rng, true));
    return callOrCheck(context, "preflop strong continue");
  }
  if (tier === "PLAYABLE") {
    if (canCheck) return checkDecision("playable free option");
    if (callBigBlinds <= 1.5 + tuning.marginalCallTolerance && rng() < 0.70) return callDecision("playable cheap call");
    return rng() < tuning.bluffFrequency + 0.12 && canRaise ? raiseDecision(context, "playable occasional steal", pickBetFraction(tuning, rng)) : foldDecision("playable too expensive");
  }
  if (tier === "MARGINAL") {
    if (canCheck) return rng() < tuning.bluffFrequency && canRaise ? raiseDecision(context, "marginal probe", pickBetFraction(tuning, rng)) : checkDecision("marginal check");
    if (callBigBlinds <= 1 + tuning.marginalCallTolerance && rng() < 0.38) return callDecision("marginal defend");
    return rng() < tuning.bluffFrequency && canRaise ? raiseDecision(context, "marginal bluff", pickBetFraction(tuning, rng)) : foldDecision("marginal fold");
  }
  if (canCheck) return rng() < tuning.bluffFrequency * 0.5 && canRaise ? raiseDecision(context, "trash rare steal", pickBetFraction(tuning, rng)) : checkDecision("trash check");
  return rng() < tuning.bluffFrequency * 0.5 && canRaise ? raiseDecision(context, "trash rare bluff", pickBetFraction(tuning, rng)) : foldDecision("trash fold");
}

function decidePostflop(context: ChallengeBotContext, rng: () => number, seed: number): ChallengeBotDecision {
  const tuning = context.botTuning ?? CHALLENGE_SESSION_CONFIG.bot;
  let info;
  try {
    info = analyzeMadeHandAndDraws(context.botHoleCards, context.communityCards);
  } catch {
    info = { madeHand: "high_card", category: 0, flushDraw: false, openEndedStraightDraw: false, gutshotStraightDraw: false, twoOvercards: false, pairPlusDraw: false };
  }
  let equityResult: { equity: number; samples: number; elapsedMs: number; timedOut: boolean; source: "rule_fallback" | "monte_carlo" };
  if (tuning.equitySamples <= 0) {
    equityResult = { equity: ruleFallbackEquity(context, info), samples: 0, elapsedMs: 0, timedOut: false, source: "rule_fallback" };
  } else {
    try {
      const estimated = estimatePostflopEquity({ botHoleCards: context.botHoleCards, communityCards: context.communityCards, seed, tuning });
      equityResult = { ...estimated, source: "monte_carlo" };
    } catch {
      equityResult = { equity: ruleFallbackEquity(context, info), samples: 0, elapsedMs: 0, timedOut: false, source: "rule_fallback" };
    }
  }
  const strongDraw = info.flushDraw || info.openEndedStraightDraw || info.pairPlusDraw;
  const adjustedEquity = Math.min(1, equityResult.equity + (strongDraw ? tuning.drawEquityBonus : 0));
  const requiredEquity = context.callAmount > 0 ? context.callAmount / Math.max(1, context.pot + context.callAmount) : 0;
  const canCheck = context.callAmount <= 0 && context.legalActions.includes("check");
  let decision: ChallengeBotDecision;
  if (canCheck) {
    if (adjustedEquity >= 0.72) {
      decision = rng() < 1 - tuning.slowPlayFrequency ? raiseDecision(context, "postflop strong value", pickBetFraction(tuning, rng, true)) : checkDecision("postflop strong slowplay");
    } else if (adjustedEquity >= 0.55) {
      decision = rng() < tuning.raiseStrongFrequency * 0.55 ? raiseDecision(context, "postflop medium value", pickBetFraction(tuning, rng)) : checkDecision("postflop medium check");
    } else if (strongDraw && adjustedEquity >= 0.35) {
      decision = rng() < tuning.semiBluffFrequency ? raiseDecision(context, "postflop semibluff draw", pickBetFraction(tuning, rng)) : checkDecision("postflop draw check");
    } else {
      decision = rng() < tuning.bluffFrequency ? raiseDecision(context, "postflop weak stab", pickBetFraction(tuning, rng)) : checkDecision("postflop weak check");
    }
  } else if (adjustedEquity >= requiredEquity + 0.25 - tuning.marginalCallTolerance) {
    decision = rng() < tuning.raiseStrongFrequency * 0.65 ? raiseDecision(context, "postflop equity edge raise", pickBetFraction(tuning, rng, true)) : callDecision("postflop equity edge call");
  } else if (adjustedEquity >= requiredEquity + 0.05 - tuning.marginalCallTolerance) {
    decision = rng() < tuning.bluffFrequency + 0.06 ? raiseDecision(context, "postflop thin raise", pickBetFraction(tuning, rng)) : callDecision("postflop profitable call");
  } else if (strongDraw && adjustedEquity + 0.03 >= requiredEquity && context.callAmount <= context.pot * 0.45) {
    decision = rng() < 0.55 ? callDecision("postflop draw price call") : foldDecision("postflop draw mixed fold");
  } else {
    decision = rng() < tuning.bluffFrequency * 0.5 ? raiseDecision(context, "postflop rare bluff raise", pickBetFraction(tuning, rng)) : foldDecision("postflop insufficient equity");
  }
  if (rng() < tuning.decisionErrorRate && context.legalActions.includes("call") && decision.action === "fold" && context.callAmount <= context.pot * 0.25) {
    decision = callDecision("difficulty-driven loose call");
  }
  return { ...decision, equity: equityResult.equity, requiredEquity, samples: equityResult.samples, elapsedMs: equityResult.elapsedMs, timedOut: equityResult.timedOut, equitySource: equityResult.source };
}

export function ruleFallbackEquity(context: ChallengeBotContext, info = analyzeMadeHandAndDraws(context.botHoleCards, context.communityCards)): number {
  let equity = madeHandRuleEquity(context, info.category);
  const drawWeight = context.street === "flop" ? 1 : context.street === "turn" ? 0.65 : 0;
  if (info.flushDraw) equity += 0.16 * drawWeight;
  if (info.openEndedStraightDraw) equity += 0.14 * drawWeight;
  else if (info.gutshotStraightDraw) equity += 0.08 * drawWeight;
  if (info.twoOvercards) equity += 0.07 * drawWeight;
  if (info.pairPlusDraw) equity += 0.04 * drawWeight;

  const tier = classifyStartingHand(context.botHoleCards);
  equity += tier === "PREMIUM" ? 0.08 : tier === "STRONG" ? 0.05 : tier === "PLAYABLE" ? 0.025 : tier === "MARGINAL" ? 0.01 : 0;

  const requiredEquity = context.callAmount > 0 ? context.callAmount / Math.max(1, context.pot + context.callAmount) : 0;
  const betToPot = context.callAmount / Math.max(1, context.pot);
  if (requiredEquity <= 0.20) equity += 0.03;
  else if (requiredEquity >= 0.45) equity -= 0.04;
  if (betToPot <= 0.25) equity += 0.03;
  else if (betToPot >= 1) equity -= 0.15;
  else if (betToPot >= 0.6) equity -= 0.08;
  return Math.max(0.05, Math.min(0.99, equity));
}

function madeHandRuleEquity(context: ChallengeBotContext, category: number): number {
  if (category >= 7) return 0.98;
  if (category === 6) return 0.95;
  if (category === 5) return 0.89;
  if (category === 4) return 0.83;
  if (category === 3) return 0.78;
  if (category === 2) return 0.72;
  if (category !== 1) return 0.20;

  const boardValues = context.communityCards.map((card) => RANK_VALUE[card.rank]);
  const holeValues = context.botHoleCards.map((card) => RANK_VALUE[card.rank]);
  if (holeValues[0] === holeValues[1]) return 0.58;
  const pairedHoleRank = holeValues.find((rank) => boardValues.includes(rank));
  if (pairedHoleRank === undefined) return 0.36;
  const distinctBoard = [...new Set(boardValues)].sort((a, b) => b - a);
  if (pairedHoleRank === distinctBoard[0]) return 0.64;
  if (pairedHoleRank === distinctBoard[1]) return 0.54;
  return 0.47;
}

function normalizeDecision(context: ChallengeBotContext, decision: ChallengeBotDecision): ChallengeBotDecision {
  if ((decision.action === "raise" || decision.action === "bet") && isLegalRaise(context, decision.amount)) return decision;
  if (decision.action === "all_in" && context.legalActions.includes("all_in")) return decision;
  if (decision.action === "call" && context.legalActions.includes("call")) return decision;
  if (decision.action === "check" && context.legalActions.includes("check")) return decision;
  if (decision.action === "fold" && context.legalActions.includes("fold")) return decision;
  if (context.legalActions.includes("call")) return { ...decision, action: "call", amount: undefined, reason: `${decision.reason}; downgraded to call` };
  if (context.legalActions.includes("check")) return { ...decision, action: "check", amount: undefined, reason: `${decision.reason}; downgraded to check` };
  return { ...decision, action: "fold", amount: undefined, reason: `${decision.reason}; downgraded to fold` };
}

function isLegalRaise(context: ChallengeBotContext, amount: number | undefined): boolean {
  if (!context.legalActions.includes("raise") && !context.legalActions.includes("bet")) return false;
  if (!Number.isFinite(amount)) return false;
  if (context.minRaiseTo !== null && amount! < context.minRaiseTo) return false;
  if (context.maxRaiseTo !== null && amount! > context.maxRaiseTo) return false;
  return amount! > 0;
}

function raiseDecision(context: ChallengeBotContext, reason: string, potFraction: number): ChallengeBotDecision {
  const action: PlayerActionType = context.legalActions.includes("bet") ? "bet" : "raise";
  const raw = context.callAmount + Math.floor(Math.max(20, context.pot * potFraction));
  const min = context.minRaiseTo ?? raw;
  const max = context.maxRaiseTo ?? context.botStack;
  const amount = Math.max(min, Math.min(max, raw));
  return { action, amount, reason };
}

function pickBetFraction(tuning: NonNullable<ChallengeBotContext["botTuning"]>, rng: () => number, preferLarge = false): number {
  const fractions = tuning.allowedBetFractions.length > 0 ? tuning.allowedBetFractions : [0.5];
  if (preferLarge) return Math.max(...fractions);
  return fractions[Math.floor(rng() * fractions.length)] ?? fractions[0];
}

function callOrCheck(context: ChallengeBotContext, reason: string): ChallengeBotDecision {
  if (context.legalActions.includes("check")) return checkDecision(reason);
  return callDecision(reason);
}

function callDecision(reason: string): ChallengeBotDecision {
  return { action: "call", reason };
}

function checkDecision(reason: string): ChallengeBotDecision {
  return { action: "check", reason };
}

function foldDecision(reason: string): ChallengeBotDecision {
  return { action: "fold", reason };
}

function startingHandKey(cards: Card[]): string {
  const [a, b] = sortedRanks(cards);
  if (a === b) return `${a}${b}`;
  return `${a}${b}${cards[0].suit === cards[1].suit ? "s" : "o"}`;
}

function sortedRanks(cards: Card[]): [string, string] {
  const ranks = cards.map((card) => card.rank).sort((a, b) => RANK_VALUE[b] - RANK_VALUE[a]);
  return [ranks[0], ranks[1]];
}
