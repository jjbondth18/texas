import type { VirtualPersonality } from "./virtual_ai_types.js";
export interface VirtualAiConfig { preflopLooseness: number; aggression: number; bluffFrequency: number; semiBluffFrequency: number; slowPlayFrequency: number; marginalCallTolerance: number; multiwayCaution: number; strongRaiseFrequency: number; allowedBetFractions: readonly number[]; }
export const VIRTUAL_AI_CONFIG: Record<VirtualPersonality, VirtualAiConfig> = {
  safe: { preflopLooseness: -.45, aggression: .38, bluffFrequency: .008, semiBluffFrequency: .12, slowPlayFrequency: .04, marginalCallTolerance: -.05, multiwayCaution: 1.2, strongRaiseFrequency: .68, allowedBetFractions: [.33, .5, .75] },
  balanced: { preflopLooseness: 0, aggression: .52, bluffFrequency: .025, semiBluffFrequency: .24, slowPlayFrequency: .07, marginalCallTolerance: 0, multiwayCaution: 1, strongRaiseFrequency: .78, allowedBetFractions: [.33, .5, .75] },
  active: { preflopLooseness: .38, aggression: .68, bluffFrequency: .045, semiBluffFrequency: .38, slowPlayFrequency: .11, marginalCallTolerance: .01, multiwayCaution: 1, strongRaiseFrequency: .88, allowedBetFractions: [.33, .5, .75] },
};
export const MULTIWAY_PENALTY = [0, 0, .055, .1, .13, .15] as const;
