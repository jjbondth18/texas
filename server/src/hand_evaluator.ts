import type { Card } from "./protocol.js";

const RANK_VALUE: Record<string, number> = {
  "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
  T: 10, J: 11, Q: 12, K: 13, A: 14,
};

const CATEGORY_NAME = [
  "high_card",
  "one_pair",
  "two_pair",
  "three_of_a_kind",
  "straight",
  "flush",
  "full_house",
  "four_of_a_kind",
  "straight_flush",
];

export interface HandEvaluation {
  category: number;
  rank: string;
  tiebreakers: number[];
  cards: string[];
  score: number[];
}

export function evaluateBestHand(cards: Card[]): HandEvaluation {
  if (cards.length < 5) {
    throw new Error("at least five cards are required to evaluate a hand");
  }
  let best: HandEvaluation | null = null;
  for (let a = 0; a < cards.length - 4; a += 1)
    for (let b = a + 1; b < cards.length - 3; b += 1)
      for (let c = b + 1; c < cards.length - 2; c += 1)
        for (let d = c + 1; d < cards.length - 1; d += 1)
          for (let e = d + 1; e < cards.length; e += 1) {
            const eval5 = evaluateFive([cards[a], cards[b], cards[c], cards[d], cards[e]]);
            if (!best || compareEvaluations(eval5, best) > 0) best = eval5;
          }
  return best!;
}

export function compareEvaluations(a: HandEvaluation, b: HandEvaluation): number {
  for (let i = 0; i < Math.max(a.score.length, b.score.length); i += 1) {
    const delta = (a.score[i] ?? 0) - (b.score[i] ?? 0);
    if (delta !== 0) return Math.sign(delta);
  }
  return 0;
}

function evaluateFive(cards: Card[]): HandEvaluation {
  const ranks = cards.map((card) => RANK_VALUE[card.rank]).sort((a, b) => b - a);
  const counts = new Map<number, number>();
  for (const rank of ranks) counts.set(rank, (counts.get(rank) ?? 0) + 1);
  const groups = [...counts.entries()].sort((a, b) => b[1] - a[1] || b[0] - a[0]);
  const flush = cards.every((card) => card.suit === cards[0].suit);
  const straightHigh = getStraightHigh([...new Set(ranks)]);

  let category = 0;
  let tiebreakers = ranks;
  if (flush && straightHigh > 0) {
    category = 8;
    tiebreakers = [straightHigh];
  } else if (groups[0][1] === 4) {
    category = 7;
    tiebreakers = [groups[0][0], groups[1][0]];
  } else if (groups[0][1] === 3 && groups[1][1] === 2) {
    category = 6;
    tiebreakers = [groups[0][0], groups[1][0]];
  } else if (flush) {
    category = 5;
  } else if (straightHigh > 0) {
    category = 4;
    tiebreakers = [straightHigh];
  } else if (groups[0][1] === 3) {
    category = 3;
    tiebreakers = [groups[0][0], ...groups.slice(1).map(([rank]) => rank).sort((a, b) => b - a)];
  } else if (groups[0][1] === 2 && groups[1][1] === 2) {
    category = 2;
    tiebreakers = [Math.max(groups[0][0], groups[1][0]), Math.min(groups[0][0], groups[1][0]), groups[2][0]];
  } else if (groups[0][1] === 2) {
    category = 1;
    tiebreakers = [groups[0][0], ...groups.slice(1).map(([rank]) => rank).sort((a, b) => b - a)];
  }

  return {
    category,
    rank: CATEGORY_NAME[category],
    tiebreakers,
    cards: cards.map((card) => card.code),
    score: [category, ...tiebreakers],
  };
}

function getStraightHigh(uniqueRanks: number[]): number {
  const ranks = uniqueRanks.slice().sort((a, b) => b - a);
  if (ranks.includes(14)) ranks.push(1);
  for (let i = 0; i <= ranks.length - 5; i += 1) {
    const run = ranks.slice(i, i + 5);
    if (run.every((rank, index) => index === 0 || rank === run[index - 1] - 1)) return run[0];
  }
  return 0;
}
