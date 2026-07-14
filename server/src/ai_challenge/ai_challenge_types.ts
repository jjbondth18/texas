import type { ActionLogEntry, Card, PlayerActionType, Phase } from "../protocol.js";

export type ChallengeStreet = "preflop" | "flop" | "turn" | "river";
export type ChallengeLegalAction = PlayerActionType;
export type StartingHandTier = "PREMIUM" | "STRONG" | "PLAYABLE" | "MARGINAL" | "TRASH";
export type ChallengeId = "rookie" | "sharp" | "boss";
export type ChallengeState = "creating" | "ready" | "started" | "completed" | "cancelled";
export type ChallengeSettlementResult = "knockout_victory" | "timeout_victory" | "defeat" | "draw" | "prestart_cancelled";
export type ChallengeDisplayResult = "victory" | "defeat" | "draw";
export type ChallengeSettlementReason =
  | "bot_eliminated"
  | "player_ahead_at_hand_limit"
  | "player_eliminated"
  | "bot_ahead_at_hand_limit"
  | "equal_stacks_at_hand_limit"
  | "player_left"
  | "prestart_failure";

export interface ChallengeBotTuning {
  equitySamples: number;
  minimumSamples: number;
  maximumSamples: number;
  timeBudgetMs: number;
  decisionErrorRate: number;
  bluffFrequency: number;
  semiBluffFrequency: number;
  slowPlayFrequency: number;
  raiseStrongFrequency: number;
  marginalCallTolerance: number;
  drawEquityBonus: number;
  allowedBetFractions: number[];
}

export interface ChallengeSessionConfig {
  mode: "ai_challenge";
  challengeId: ChallengeId;
  displayName: string;
  walletImpact: false;
  startingStack: number;
  smallBlind: number;
  bigBlind: number;
  maxHands: number;
  entryFeeChips: number;
  timeoutVictoryProfitMultiplier: number;
  knockoutVictoryProfitMultiplier: number;
  drawRefundMultiplier: number;
  bot: ChallengeBotTuning;
  rebuyAllowed: false;
  addChipsAllowed: false;
}

export interface ChallengeBotContext {
  botHoleCards: Card[];
  communityCards: Card[];
  street: ChallengeStreet;
  pot: number;
  callAmount: number;
  minRaiseTo: number | null;
  maxRaiseTo: number | null;
  botStack: number;
  playerStack: number;
  buttonSeat: number;
  botSeat: number;
  legalActions: ChallengeLegalAction[];
  visibleActionHistory: ActionLogEntry[];
  handIndex: number;
  decisionIndex: number;
  sessionSeed: number;
  botTuning?: ChallengeBotTuning;
}

export interface ChallengeBotDecision {
  action: PlayerActionType;
  amount?: number;
  reason: string;
  equity?: number;
  requiredEquity?: number;
  samples?: number;
  elapsedMs?: number;
  timedOut?: boolean;
  equitySource?: "rule_fallback" | "monte_carlo";
}

export interface MadeAndDrawInfo {
  madeHand: string;
  category: number;
  flushDraw: boolean;
  openEndedStraightDraw: boolean;
  gutshotStraightDraw: boolean;
  twoOvercards: boolean;
  pairPlusDraw: boolean;
}

export type ChallengePhase = Extract<Phase, "preflop" | "flop" | "turn" | "river">;
