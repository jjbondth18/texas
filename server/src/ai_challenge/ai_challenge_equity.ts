import { createDeck } from "../deck.js";
import { compareEvaluations, evaluateBestHand } from "../hand_evaluator.js";
import type { Card } from "../protocol.js";
import { CHALLENGE_BOT_CONFIG } from "./ai_challenge_config.js";
import type { MadeAndDrawInfo } from "./ai_challenge_types.js";

const RANK_VALUE: Record<string, number> = {
  "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
  T: 10, J: 11, Q: 12, K: 13, A: 14,
};

export interface EquityResult {
  equity: number;
  samples: number;
  elapsedMs: number;
  timedOut: boolean;
}

export function estimatePostflopEquity(params: {
  botHoleCards: Card[];
  communityCards: Card[];
  seed: number;
  samples?: number;
  timeBudgetMs?: number;
}): EquityResult {
  const requested = params.samples ?? CHALLENGE_BOT_CONFIG.equity.samples;
  const targetSamples = clampInt(requested, CHALLENGE_BOT_CONFIG.equity.minimumSamples, CHALLENGE_BOT_CONFIG.equity.maximumSamples);
  const timeBudgetMs = params.timeBudgetMs ?? CHALLENGE_BOT_CONFIG.equity.timeBudgetMs;
  const started = Date.now();
  const usedCodes = new Set([...params.botHoleCards, ...params.communityCards].map((card) => card.code));
  const baseDeck = createDeck().filter((card) => !usedCodes.has(card.code));
  const rng = seededRandom(params.seed);
  let wins = 0;
  let ties = 0;
  let completed = 0;
  let timedOut = false;

  for (let i = 0; i < targetSamples; i += 1) {
    if (completed >= CHALLENGE_BOT_CONFIG.equity.minimumSamples && Date.now() - started >= timeBudgetMs) {
      timedOut = true;
      break;
    }
    const deck = shuffled(baseDeck, rng);
    const playerHole = [deck[0], deck[1]];
    const board = params.communityCards.slice();
    let cursor = 2;
    while (board.length < 5) board.push(deck[cursor++]);
    try {
      const botEval = evaluateBestHand([...params.botHoleCards, ...board]);
      const playerEval = evaluateBestHand([...playerHole, ...board]);
      const cmp = compareEvaluations(botEval, playerEval);
      if (cmp > 0) wins += 1;
      else if (cmp === 0) ties += 1;
      completed += 1;
    } catch {
      break;
    }
  }

  const samples = Math.max(1, completed);
  return {
    equity: (wins + ties * 0.5) / samples,
    samples,
    elapsedMs: Date.now() - started,
    timedOut,
  };
}

export function analyzeMadeHandAndDraws(holeCards: Card[], communityCards: Card[]): MadeAndDrawInfo {
  const cards = [...holeCards, ...communityCards];
  const enoughForMade = cards.length >= 5;
  const made = enoughForMade ? evaluateBestHand(cards) : undefined;
  const suitCounts = new Map<string, number>();
  for (const card of cards) suitCounts.set(card.suit, (suitCounts.get(card.suit) ?? 0) + 1);
  const flushDraw = [...suitCounts.values()].some((count) => count === 4);
  const ranks = [...new Set(cards.map((card) => RANK_VALUE[card.rank]))];
  if (ranks.includes(14)) ranks.push(1);
  const rankSet = new Set(ranks);
  let openEndedStraightDraw = false;
  let gutshotStraightDraw = false;
  for (let low = 1; low <= 10; low += 1) {
    const window = [low, low + 1, low + 2, low + 3, low + 4];
    const present = window.filter((rank) => rankSet.has(rank));
    if (present.length !== 4) continue;
    if (!rankSet.has(low) || !rankSet.has(low + 4)) openEndedStraightDraw = true;
    else gutshotStraightDraw = true;
  }
  const boardHigh = Math.max(...communityCards.map((card) => RANK_VALUE[card.rank]), 0);
  const overcards = holeCards.filter((card) => RANK_VALUE[card.rank] > boardHigh).length;
  const hasPair = (made?.category ?? 0) >= 1;
  const hasDraw = flushDraw || openEndedStraightDraw || gutshotStraightDraw;
  return {
    madeHand: made?.rank ?? "high_card",
    category: made?.category ?? 0,
    flushDraw,
    openEndedStraightDraw,
    gutshotStraightDraw,
    twoOvercards: communityCards.length >= 3 && overcards >= 2,
    pairPlusDraw: hasPair && hasDraw,
  };
}

export function seedFromParts(...parts: Array<string | number>): number {
  let hash = 2166136261;
  for (const part of parts.join(":")) {
    hash ^= part.charCodeAt(0);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

export function seededRandom(seed: number): () => number {
  let state = seed >>> 0;
  return () => {
    state = (1664525 * state + 1013904223) >>> 0;
    return state / 0x100000000;
  };
}

function shuffled(cards: Card[], rng: () => number): Card[] {
  const result = cards.slice();
  for (let i = result.length - 1; i > 0; i -= 1) {
    const j = Math.floor(rng() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

function clampInt(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, Math.floor(value)));
}
