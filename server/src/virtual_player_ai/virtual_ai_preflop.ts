import type { Card } from "../protocol.js";
import type { VirtualAiConfig } from "./virtual_ai_config.js";
import type { StartingHandTier, VirtualBotContext, VirtualBotDecision } from "./virtual_ai_types.js";
const V: Record<Card["rank"], number> = {"2":2,"3":3,"4":4,"5":5,"6":6,"7":7,"8":8,"9":9,T:10,J:11,Q:12,K:13,A:14};
const S: Record<StartingHandTier, number> = {premium:5,strong:4,playable:3,speculative:2,marginal:1,trash:0};
const P: Record<VirtualBotContext["position"], number> = {early:3.45,middle:3.05,cutoff:2.5,button:2.25,small_blind:3.05,big_blind:2.85};
export function classifyVirtualStartingHand(cards: Card[]): StartingHandTier {
  if (cards.length !== 2) return "trash";
  const [a,b] = cards.map(c=>V[c.rank]).sort((x,y)=>y-x), pair=a===b, suited=cards[0].suit===cards[1].suit, gap=a-b;
  if ((pair&&a>=11)||(a===14&&b>=13)) return "premium";
  if ((pair&&a>=8)||(a>=13&&b>=11)||(suited&&a===14&&b>=10)) return "strong";
  if ((pair&&a>=5)||(suited&&a>=11&&b>=9)||(a>=12&&b>=10)) return "playable";
  if (pair||(suited&&gap<=2&&a>=7)||(suited&&a===14)||(suited&&a>=12&&b>=7)) return "speculative";
  return (suited&&a>=10)||(a>=11&&b>=9) ? "marginal" : "trash";
}
export function decideVirtualPreflop(c: VirtualBotContext, cfg: VirtualAiConfig, rng:()=>number): VirtualBotDecision {
  const tier=classifyVirtualStartingHand(c.botHoleCards), score=S[tier];
  const raises=c.publicActionHistory.filter(a=>a.street==="preflop"&&(a.action==="raise"||a.action==="all_in")).length;
  const calls=c.publicActionHistory.filter(a=>a.street==="preflop"&&a.action==="call").length, callBb=c.callAmount/Math.max(1,c.bigBlind), stackBb=c.botStack/Math.max(1,c.bigBlind);
  let threshold=P[c.position]-cfg.preflopLooseness*(c.position==="button"||c.position==="cutoff"?.8:.25)+raises*.72+Math.max(0,calls-1)*.42+Math.max(0,c.opponentsStillInHand-2)*.16*cfg.multiwayCaution;
  threshold += callBb>=5?1.5:callBb>3?.55:0; if(stackBb<25&&tier==="speculative")threshold+=.8; if(stackBb>70&&tier==="speculative"&&callBb<=3)threshold-=.35;
  const internalStrength=Math.min(.99,.1+score*.17), facing=c.callAmount>0;
  if(stackBb<=8&&tier==="premium"&&raises>0&&c.legalActions.includes("all_in")&&rng()<.78)return {action:"all_in",internalReason:"preflop_value",internalStrength};
  if(tier==="premium"&&raises>=2){if(c.legalActions.includes("raise")&&rng()<cfg.strongRaiseFrequency*.7)return {action:"raise",internalReason:"preflop_value",internalStrength};return {action:"call",internalReason:"preflop_pressure",internalStrength};}
  if(score<threshold)return {action:facing?"fold":"check",internalReason:raises?"preflop_pressure":"preflop_position",internalStrength};
  if(c.legalActions.includes("raise")&&(tier==="premium"||(!facing&&score>=threshold+.55))&&rng()<cfg.strongRaiseFrequency)return {action:"raise",internalReason:"preflop_value",internalStrength};
  return {action:facing?"call":c.legalActions.includes("raise")&&rng()<cfg.aggression*.7?"raise":"check",internalReason:facing?"preflop_pressure":"preflop_position",internalStrength};
}
