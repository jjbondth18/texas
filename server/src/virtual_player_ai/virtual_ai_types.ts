import type { Card } from "../protocol.js";
export type VirtualPersonality = "safe" | "balanced" | "active";
export type VirtualAction = "fold" | "check" | "call" | "raise" | "all_in";
export type VirtualStreet = "preflop" | "flop" | "turn" | "river";
export type VirtualPosition = "early" | "middle" | "cutoff" | "button" | "small_blind" | "big_blind";
export interface PublicPokerAction { playerId: string; street: VirtualStreet; action: VirtualAction; amount: number; }
export interface VirtualBotContext {
  botPlayerId: string; botHoleCards: Card[]; communityCards: Card[]; street: VirtualStreet;
  pot: number; currentBet: number; callAmount: number; minRaiseTo: number | null; maxRaiseTo: number | null;
  botStack: number; botCommittedThisStreet: number; bigBlind: number; smallBlind: number;
  seatCount: number; activePlayerCount: number; opponentsStillInHand: number; position: VirtualPosition;
  isInPosition: boolean; legalActions: VirtualAction[]; publicActionHistory: PublicPokerAction[];
  handIndex: number; decisionIndex: number; sessionSeed: string;
}
export type VirtualDecisionReason = "preflop_value" | "preflop_position" | "preflop_pressure" | "postflop_value" | "postflop_draw" | "pot_odds" | "multiway_caution" | "controlled_bluff" | "legal_fallback";
export interface VirtualBotDecision { action: VirtualAction; raiseTo?: number; internalReason: VirtualDecisionReason; internalStrength: number; }
export type StartingHandTier = "premium" | "strong" | "playable" | "speculative" | "marginal" | "trash";
export interface PostflopAssessment {
  madeHand: "high_card" | "bottom_pair" | "middle_pair" | "top_pair_weak_kicker" | "top_pair_strong_kicker" | "overpair" | "two_pair" | "three_of_a_kind" | "straight" | "flush" | "full_house" | "four_of_a_kind" | "straight_flush";
  estimatedStrength: number; flushDraw: boolean; openEndedStraightDraw: boolean; gutshot: boolean;
  twoOvercards: boolean; pairPlusDraw: boolean; comboDraw: boolean; boardWetness: number;
}
