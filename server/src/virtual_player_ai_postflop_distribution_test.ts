import type { Card } from "./protocol.js";
import { context } from "./virtual_player_ai_test.js";
import { decideVirtualBotAction } from "./virtual_player_ai/virtual_ai_policy.js";
import type { VirtualAction } from "./virtual_player_ai/virtual_ai_types.js";
const C=(rank:Card["rank"],suit:Card["suit"]):Card=>({rank,suit,code:rank+suit});
const cases={
 air:[[C("3","S"),C("4","D")],[C("A","H"),C("K","C"),C("9","S")]],
 weak_pair:[[C("9","S"),C("4","D")],[C("4","H"),C("K","C"),C("A","S")]],
 top_pair_weak:[[C("A","S"),C("4","D")],[C("A","H"),C("9","C"),C("2","S")]],
 top_pair_strong:[[C("A","S"),C("K","D")],[C("A","H"),C("9","C"),C("2","S")]],
 overpair:[[C("A","S"),C("A","D")],[C("K","H"),C("9","C"),C("2","S")]],
 two_pair:[[C("A","S"),C("9","D")],[C("A","H"),C("9","C"),C("2","S")]],
 trips:[[C("9","S"),C("9","D")],[C("9","H"),C("K","C"),C("2","S")]],
 strong_draw:[[C("A","H"),C("Q","H")],[C("J","H"),C("T","H"),C("2","S")]],
 weak_draw:[[C("8","S"),C("7","D")],[C("9","H"),C("6","C"),C("2","S")]],
 straight_flush:[[C("9","S"),C("8","D")],[C("7","H"),C("6","C"),C("5","S")]],
 full_house_plus:[[C("A","S"),C("A","D")],[C("A","H"),C("K","C"),C("K","S")]],
} satisfies Record<string,[Card[],Card[]]>;
const bets=[0,.33,.5,.75,1.25],ways=[1,2,4];
for(const p of ["safe","balanced","active"] as const){console.log(`\n${p.toUpperCase()} POSTFLOP`);for(const [name,[hole,board]] of Object.entries(cases)){const summary:Record<string,Record<VirtualAction,number>>={};for(const opponents of ways)for(const fraction of bets){const counts:Record<VirtualAction,number>={fold:0,check:0,call:0,raise:0,all_in:0};for(let i=0;i<200;i++){const pot=100,callAmount=Math.round(pot*fraction),d=decideVirtualBotAction(context({street:"flop",botHoleCards:hole,communityCards:board,pot,callAmount,opponentsStillInHand:opponents,legalActions:callAmount?["fold","call","raise","all_in"]:["check","raise","all_in"],decisionIndex:i}),p);counts[d.action]++;}summary[`${opponents+1}way_${fraction}pot`]=counts;}console.log(name,JSON.stringify(summary));}}
