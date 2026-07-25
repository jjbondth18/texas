import type { PlayerActionType } from "./protocol.js";
import type { PublicVirtualPlayerProfile } from "./public_virtual_players.js";
import { decideVirtualBotAction } from "./virtual_player_ai/virtual_ai_policy.js";
import type { VirtualBotContext, VirtualBotDecision, VirtualPersonality } from "./virtual_player_ai/virtual_ai_types.js";

export interface VirtualPlayerAuthorityDecision extends Omit<VirtualBotDecision, "action"> {
  action: PlayerActionType;
  amount?: number;
  personality: VirtualPersonality;
}

export function mapVirtualPersonality(profile: Pick<PublicVirtualPlayerProfile, "skillProfile">): VirtualPersonality {
  switch (profile.skillProfile) {
    case "tight_passive": return "safe";
    case "tight_aggressive": return "active";
    case "beginner": return "safe";
    case "loose_passive":
    case "balanced":
    default: return "balanced";
  }
}

export function adaptVirtualBotDecision(context: VirtualBotContext, decision: VirtualBotDecision, personality: VirtualPersonality): VirtualPlayerAuthorityDecision {
  if (decision.action === "raise") {
    if (decision.raiseTo === undefined) throw new Error("virtual_raise_target_missing");
    return { ...decision, action: context.currentBet === 0 ? "bet" : "raise", amount: decision.raiseTo, personality };
  }
  return { ...decision, action: decision.action, personality };
}

export function decideVirtualPlayerAction(context: VirtualBotContext, profile: Pick<PublicVirtualPlayerProfile, "skillProfile">): VirtualPlayerAuthorityDecision {
  const personality = mapVirtualPersonality(profile);
  return adaptVirtualBotDecision(context, decideVirtualBotAction(context, personality), personality);
}