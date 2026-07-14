import type { ActionLogEntry, Card, PlayerActionType, Phase } from "../protocol.js";

export type ChallengeStreet = "preflop" | "flop" | "turn" | "river";
export type ChallengeLegalAction = PlayerActionType;
export type StartingHandTier = "PREMIUM" | "STRONG" | "PLAYABLE" | "MARGINAL" | "TRASH";

export interface ChallengeSessionConfig {
  mode: "ai_challenge";
  challengeId: "rule_bot_v1";
  walletImpact: false;
  startingStack: number;
  smallBlind: number;
  bigBlind: number;
  maxHands: number;
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
