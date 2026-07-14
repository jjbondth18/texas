import type { ChallengeSessionConfig } from "./ai_challenge_types.js";

export const CHALLENGE_SESSION_CONFIG: ChallengeSessionConfig = {
  mode: "ai_challenge",
  challengeId: "rule_bot_v1",
  walletImpact: false,
  startingStack: 1000,
  smallBlind: 10,
  bigBlind: 20,
  maxHands: 20,
  rebuyAllowed: false,
  addChipsAllowed: false,
};

export const CHALLENGE_BOT_CONFIG = {
  equity: {
    samples: 160,
    minimumSamples: 80,
    maximumSamples: 240,
    timeBudgetMs: 20,
    drawBonus: 0.04,
  },
  preflop: {
    largeRaiseBigBlinds: 5,
    cheapCallBigBlinds: 1.5,
    openRaisePot: 0.75,
    reraisePot: 0.75,
    trashBluff: 0.04,
  },
  postflop: {
    strongValue: 0.72,
    mediumValue: 0.55,
    drawSemibluffMin: 0.35,
    bigEdge: 0.25,
    callEdge: 0.05,
    weakBluff: 0.06,
  },
  betSizing: {
    halfPot: 0.5,
    threeQuarterPot: 0.75,
  },
};

export const STARTING_HAND_TIERS = {
  PREMIUM: [
    "AA", "KK", "QQ", "JJ", "TT",
    "AKs", "AKo", "AQs", "AQo", "AJs", "KQs",
  ],
  STRONG: [
    "99", "88", "77", "66",
    "AJs", "AJo", "ATs", "ATo", "A9s", "A8s", "A7s", "A6s", "A5s", "A4s", "A3s", "A2s",
    "KQs", "KQo", "KJs", "KJo", "KTs", "QJs", "JTs",
  ],
  PLAYABLE: [
    "55", "44", "33", "22",
    "A9o", "A8o", "A7o", "KTo", "QJo",
    "QTs", "Q9s", "J9s", "T9s", "98s", "87s", "76s", "65s",
  ],
};
