import type { Card, PlayerActionType, PrivateSnapshot } from "../protocol.js";
import { CHALLENGE_BOT_CONFIG, STARTING_HAND_TIERS } from "./ai_challenge_config.js";
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
  const tier = classifyStartingHand(context.botHoleCards);
  const callBigBlinds = context.callAmount / 20;
  const facingRaise = context.callAmount > 20;
  const canCheck = context.legalActions.includes("check");
  const canRaise = context.legalActions.includes("raise") || context.legalActions.includes("bet");
  if (tier === "PREMIUM") {
    if (canRaise && rng() < 0.86) return raiseDecision(context, "preflop premium value", CHALLENGE_BOT_CONFIG.preflop.reraisePot);
    return callOrCheck(context, "preflop premium trap");
  }
  if (tier === "STRONG") {
    if (facingRaise && callBigBlinds > CHALLENGE_BOT_CONFIG.preflop.largeRaiseBigBlinds && rng() < 0.35) return foldDecision("strong hand facing oversized raise");
    if (canRaise && rng() < (facingRaise ? 0.34 : 0.62)) return raiseDecision(context, "preflop strong pressure", CHALLENGE_BOT_CONFIG.preflop.openRaisePot);
    return callOrCheck(context, "preflop strong continue");
  }
  if (tier === "PLAYABLE") {
    if (canCheck) return checkDecision("playable free option");
    if (callBigBlinds <= CHALLENGE_BOT_CONFIG.preflop.cheapCallBigBlinds && rng() < 0.70) return callDecision("playable cheap call");
    return rng() < 0.18 && canRaise ? raiseDecision(context, "playable occasional steal", 0.5) : foldDecision("playable too expensive");
  }
  if (tier === "MARGINAL") {
    if (canCheck) return rng() < 0.10 && canRaise ? raiseDecision(context, "marginal probe", 0.5) : checkDecision("marginal check");
    if (callBigBlinds <= 1 && rng() < 0.38) return callDecision("marginal defend");
    return rng() < 0.08 && canRaise ? raiseDecision(context, "marginal bluff", 0.5) : foldDecision("marginal fold");
  }
  if (canCheck) return rng() < CHALLENGE_BOT_CONFIG.preflop.trashBluff && canRaise ? raiseDecision(context, "trash rare steal", 0.5) : checkDecision("trash check");
  return rng() < CHALLENGE_BOT_CONFIG.preflop.trashBluff && canRaise ? raiseDecision(context, "trash rare bluff", 0.5) : foldDecision("trash fold");
}

function decidePostflop(context: ChallengeBotContext, rng: () => number, seed: number): ChallengeBotDecision {
  let info;
  try {
    info = analyzeMadeHandAndDraws(context.botHoleCards, context.communityCards);
  } catch {
    info = { madeHand: "high_card", category: 0, flushDraw: false, openEndedStraightDraw: false, gutshotStraightDraw: false, twoOvercards: false, pairPlusDraw: false };
  }
  let equityResult;
  try {
    equityResult = estimatePostflopEquity({ botHoleCards: context.botHoleCards, communityCards: context.communityCards, seed });
  } catch {
    equityResult = { equity: fallbackEquityForCategory(info.category), samples: 0, elapsedMs: 0, timedOut: false };
  }
  const strongDraw = info.flushDraw || info.openEndedStraightDraw || info.pairPlusDraw;
  const adjustedEquity = Math.min(1, equityResult.equity + (strongDraw ? CHALLENGE_BOT_CONFIG.equity.drawBonus : 0));
  const requiredEquity = context.callAmount > 0 ? context.callAmount / Math.max(1, context.pot + context.callAmount) : 0;
  const canCheck = context.callAmount <= 0 && context.legalActions.includes("check");
  let decision: ChallengeBotDecision;
  if (canCheck) {
    if (adjustedEquity >= CHALLENGE_BOT_CONFIG.postflop.strongValue) {
      decision = rng() < 0.70 ? raiseDecision(context, "postflop strong value", CHALLENGE_BOT_CONFIG.betSizing.threeQuarterPot) : checkDecision("postflop strong slowplay");
    } else if (adjustedEquity >= CHALLENGE_BOT_CONFIG.postflop.mediumValue) {
      decision = rng() < 0.40 ? raiseDecision(context, "postflop medium value", CHALLENGE_BOT_CONFIG.betSizing.halfPot) : checkDecision("postflop medium check");
    } else if (strongDraw && adjustedEquity >= CHALLENGE_BOT_CONFIG.postflop.drawSemibluffMin) {
      decision = rng() < 0.20 ? raiseDecision(context, "postflop semibluff draw", CHALLENGE_BOT_CONFIG.betSizing.halfPot) : checkDecision("postflop draw check");
    } else {
      decision = rng() < CHALLENGE_BOT_CONFIG.postflop.weakBluff ? raiseDecision(context, "postflop weak stab", CHALLENGE_BOT_CONFIG.betSizing.halfPot) : checkDecision("postflop weak check");
    }
  } else if (adjustedEquity >= requiredEquity + CHALLENGE_BOT_CONFIG.postflop.bigEdge) {
    decision = rng() < 0.45 ? raiseDecision(context, "postflop equity edge raise", CHALLENGE_BOT_CONFIG.betSizing.threeQuarterPot) : callDecision("postflop equity edge call");
  } else if (adjustedEquity >= requiredEquity + CHALLENGE_BOT_CONFIG.postflop.callEdge) {
    decision = rng() < 0.12 ? raiseDecision(context, "postflop thin raise", CHALLENGE_BOT_CONFIG.betSizing.halfPot) : callDecision("postflop profitable call");
  } else if (strongDraw && adjustedEquity + 0.03 >= requiredEquity && context.callAmount <= context.pot * 0.45) {
    decision = rng() < 0.55 ? callDecision("postflop draw price call") : foldDecision("postflop draw mixed fold");
  } else {
    decision = rng() < 0.03 ? raiseDecision(context, "postflop rare bluff raise", CHALLENGE_BOT_CONFIG.betSizing.halfPot) : foldDecision("postflop insufficient equity");
  }
  return { ...decision, equity: equityResult.equity, requiredEquity, samples: equityResult.samples, elapsedMs: equityResult.elapsedMs, timedOut: equityResult.timedOut };
}

function fallbackEquityForCategory(category: number): number {
  if (category >= 5) return 0.82;
  if (category >= 3) return 0.68;
  if (category >= 1) return 0.48;
  return 0.28;
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
