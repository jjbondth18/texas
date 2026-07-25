import {VIRTUAL_AI_CONFIG} from "./virtual_ai_config.js";
import {assessVirtualPostflop} from "./virtual_ai_postflop.js";
import {decideVirtualPreflop} from "./virtual_ai_preflop.js";
import {createVirtualAiRng} from "./virtual_ai_rng.js";
import type {VirtualAction,VirtualBotContext,VirtualBotDecision,VirtualDecisionReason,VirtualPersonality} from "./virtual_ai_types.js";
export function decideVirtualBotAction(c:VirtualBotContext,p:VirtualPersonality="balanced"):VirtualBotDecision{
 const cfg=VIRTUAL_AI_CONFIG[p],rng=createVirtualAiRng([c.sessionSeed,c.botPlayerId,c.handIndex,c.decisionIndex]);
 return enforceLegalDecision(c,c.street==="preflop"?decideVirtualPreflop(c,cfg,rng):post(c,cfg,rng));
}
function post(c:VirtualBotContext,cfg:typeof VIRTUAL_AI_CONFIG["balanced"],rng:()=>number):VirtualBotDecision{
 const a=assessVirtualPostflop(c),required=c.callAmount/Math.max(1,c.pot+c.callAmount),facing=c.callAmount>0,strongDraw=a.comboDraw||a.flushDraw||a.openEndedStraightDraw,multi=c.opponentsStillInHand>=2,spr=c.botStack/Math.max(1,c.pot);
 let action:VirtualAction,internalReason:VirtualDecisionReason;
 if(spr<=.5&&a.estimatedStrength>=.68&&c.legalActions.includes("all_in")&&rng()<.8){action="all_in";internalReason="postflop_value";}
 else if(!multi&&spr<=1&&a.comboDraw&&c.legalActions.includes("all_in")&&rng()<.06){action="all_in";internalReason="postflop_draw";}
 else if(a.estimatedStrength>=.76||(a.estimatedStrength>=.64&&spr<2.5)){action=rng()<cfg.slowPlayFrequency&&!facing?"check":"raise";internalReason="postflop_value";}
 else if(facing&&a.estimatedStrength+cfg.marginalCallTolerance>=required+.07){action=strongDraw&&!multi&&rng()<cfg.semiBluffFrequency?"raise":"call";internalReason=strongDraw?"postflop_draw":"pot_odds";}
 else if(facing){action=a.estimatedStrength+(strongDraw?.08:0)>=required&&c.callAmount<=c.pot*.55&&(!multi||a.estimatedStrength>=.54)?"call":"fold";internalReason=multi?"multiway_caution":"pot_odds";}
 else if(!multi&&a.madeHand==="high_card"&&rng()<cfg.bluffFrequency){action="raise";internalReason="controlled_bluff";}
 else if(a.estimatedStrength>=.52||(strongDraw&&rng()<cfg.semiBluffFrequency)){action=rng()<cfg.aggression?"raise":"check";internalReason=strongDraw?"postflop_draw":"postflop_value";}
 else{action="check";internalReason=multi?"multiway_caution":"pot_odds";}
 return{action,internalReason,internalStrength:a.estimatedStrength};
}
export function enforceLegalDecision(c:VirtualBotContext,d:VirtualBotDecision):VirtualBotDecision{
 const legal=new Set(c.legalActions);
 if(d.action==="raise"){const raiseTo=legalRaiseTo(c,d.raiseTo);if(legal.has("raise")&&raiseTo!==null)return{...d,raiseTo};}
 else if(d.action==="all_in"&&legal.has("all_in"))return{...d,raiseTo:undefined};
 else if(legal.has(d.action))return{...d,raiseTo:undefined};
 const action:VirtualAction=legal.has("call")?"call":legal.has("check")?"check":legal.has("fold")?"fold":c.legalActions[0]??"fold";
 return{action,internalReason:"legal_fallback",internalStrength:Number.isFinite(d.internalStrength)?Math.max(.05,Math.min(.99,d.internalStrength)):.05};
}
function legalRaiseTo(c:VirtualBotContext,requested?:number):number|null{
 if(c.minRaiseTo===null||c.maxRaiseTo===null)return null;
 const min=Math.ceil(Math.max(0,c.minRaiseTo)),max=Math.floor(Math.min(c.maxRaiseTo,c.botCommittedThisStreet+Math.max(0,c.botStack)));if(!Number.isFinite(min)||!Number.isFinite(max)||max<min)return null;
 if(requested!==undefined&&Number.isFinite(requested))return Math.max(min,Math.min(max,Math.round(requested)));
 const fraction=c.street==="preflop"?.5:assessVirtualPostflop(c).boardWetness>=.5?.75:.5;
 return Math.max(min,Math.min(max,Math.round(c.currentBet+c.pot*fraction)));
}
export type {VirtualBotContext,VirtualBotDecision,VirtualPersonality} from "./virtual_ai_types.js";
