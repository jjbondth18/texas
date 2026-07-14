import type {
  ChallengeDisplayResult,
  ChallengeId,
  ChallengeSessionConfig,
  ChallengeSettlementReason,
  ChallengeSettlementResult,
} from "./ai_challenge_types.js";

const ECONOMY = {
  timeoutVictoryProfitMultiplier: 0.5,
  knockoutVictoryProfitMultiplier: 1.0,
  drawRefundMultiplier: 1.0,
} as const;

export const CHALLENGE_SESSION_CONFIGS: Record<ChallengeId, ChallengeSessionConfig> = {
  rookie: {
    mode: "ai_challenge",
    challengeId: "rookie",
    displayName: "Rookie",
    walletImpact: false,
    startingStack: 1000,
    smallBlind: 10,
    bigBlind: 20,
    maxHands: 20,
    entryFeeChips: 200,
    ...ECONOMY,
    bot: {
      equitySamples: 0,
      minimumSamples: 0,
      maximumSamples: 0,
      timeBudgetMs: 12,
      decisionErrorRate: 0.14,
      bluffFrequency: 0.02,
      semiBluffFrequency: 0.08,
      slowPlayFrequency: 0.18,
      raiseStrongFrequency: 0.58,
      marginalCallTolerance: -0.02,
      drawEquityBonus: 0.02,
      allowedBetFractions: [0.5],
    },
    rebuyAllowed: false,
    addChipsAllowed: false,
  },
  sharp: {
    mode: "ai_challenge",
    challengeId: "sharp",
    displayName: "Sharp",
    walletImpact: false,
    startingStack: 1500,
    smallBlind: 15,
    bigBlind: 30,
    maxHands: 25,
    entryFeeChips: 500,
    ...ECONOMY,
    bot: {
      equitySamples: 60,
      minimumSamples: 30,
      maximumSamples: 80,
      timeBudgetMs: 18,
      decisionErrorRate: 0.06,
      bluffFrequency: 0.06,
      semiBluffFrequency: 0.20,
      slowPlayFrequency: 0.14,
      raiseStrongFrequency: 0.70,
      marginalCallTolerance: 0.05,
      drawEquityBonus: 0.04,
      allowedBetFractions: [0.5, 0.75],
    },
    rebuyAllowed: false,
    addChipsAllowed: false,
  },
  boss: {
    mode: "ai_challenge",
    challengeId: "boss",
    displayName: "Boss",
    walletImpact: false,
    startingStack: 2000,
    smallBlind: 20,
    bigBlind: 40,
    maxHands: 30,
    entryFeeChips: 1000,
    ...ECONOMY,
    bot: {
      equitySamples: 100,
      minimumSamples: 50,
      maximumSamples: 160,
      timeBudgetMs: 20,
      decisionErrorRate: 0.025,
      bluffFrequency: 0.08,
      semiBluffFrequency: 0.28,
      slowPlayFrequency: 0.08,
      raiseStrongFrequency: 0.78,
      marginalCallTolerance: 0.08,
      drawEquityBonus: 0.05,
      allowedBetFractions: [0.5, 0.75],
    },
    rebuyAllowed: false,
    addChipsAllowed: false,
  },
};

export const DEFAULT_CHALLENGE_ID: ChallengeId = "rookie";
export const CHALLENGE_SESSION_CONFIG = CHALLENGE_SESSION_CONFIGS[DEFAULT_CHALLENGE_ID];

export function isChallengeId(value: string): value is ChallengeId {
  return value === "rookie" || value === "sharp" || value === "boss";
}

export function challengeConfigById(value: string | undefined): ChallengeSessionConfig {
  const challengeId = value && isChallengeId(value) ? value : DEFAULT_CHALLENGE_ID;
  return CHALLENGE_SESSION_CONFIGS[challengeId];
}

export function challengeCatalog() {
  return Object.values(CHALLENGE_SESSION_CONFIGS).map((config) => ({
    challenge_id: config.challengeId,
    display_name: config.displayName,
    starting_stack: config.startingStack,
    small_blind: config.smallBlind,
    big_blind: config.bigBlind,
    max_hands: config.maxHands,
    entry_fee_chips: config.entryFeeChips,
    timeout_win_profit_chips: challengePayout(config, "timeout_victory").netResultChips,
    knockout_win_profit_chips: challengePayout(config, "knockout_victory").netResultChips,
  }));
}

export function challengePayout(config: ChallengeSessionConfig, result: ChallengeSettlementResult) {
  const entryFee = config.entryFeeChips;
  let payout = 0;
  if (result === "knockout_victory") payout = entryFee * (1 + config.knockoutVictoryProfitMultiplier);
  else if (result === "timeout_victory") payout = entryFee * (1 + config.timeoutVictoryProfitMultiplier);
  else if (result === "draw" || result === "prestart_cancelled") payout = entryFee * config.drawRefundMultiplier;
  return {
    entryFeeChips: entryFee,
    walletPayoutChips: Math.floor(payout),
    netResultChips: Math.floor(payout) - entryFee,
  };
}

export function displayResultForSettlement(result: ChallengeSettlementResult): ChallengeDisplayResult {
  if (result === "knockout_victory" || result === "timeout_victory") return "victory";
  if (result === "draw" || result === "prestart_cancelled") return "draw";
  return "defeat";
}

export function settlementReasonText(reason: ChallengeSettlementReason): string {
  switch (reason) {
    case "bot_eliminated":
      return "Opponent eliminated.";
    case "player_ahead_at_hand_limit":
      return "You were ahead at the hand limit.";
    case "player_eliminated":
      return "Your event stack reached zero.";
    case "bot_ahead_at_hand_limit":
      return "Opponent was ahead at the hand limit.";
    case "equal_stacks_at_hand_limit":
      return "Event stacks were equal at the hand limit.";
    case "player_left":
      return "Challenge ended because you left after it started.";
    case "prestart_failure":
      return "Challenge was cancelled before the first hand.";
  }
}

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
