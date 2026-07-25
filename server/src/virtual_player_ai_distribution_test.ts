import type { Card } from "./protocol.js";
import { context } from "./virtual_player_ai_test.js";
import { decideVirtualBotAction } from "./virtual_player_ai/virtual_ai_policy.js";
import type { PublicPokerAction, VirtualAction, VirtualPersonality, VirtualPosition } from "./virtual_player_ai/virtual_ai_types.js";
const personalities:VirtualPersonality[]=["safe","balanced","active"],positions:VirtualPosition[]=["early","middle","cutoff","button","small_blind","big_blind"];
const ranks:Card["rank"][]=["2","3","4","5","6","7","8","9","T","J","Q","K","A"],suits:Card["suit"][]=["C","D","H","S"];
const deck=ranks.flatMap(rank=>suits.map(suit=>({rank,suit,code:rank+suit}))),hands:Card[][]=[];for(let a=0;a<deck.length-1;a++)for(let b=a+1;b<deck.length;b++)hands.push([deck[a],deck[b]]);
const hand=(i:number):Card[]=>hands[i%hands.length];
const empty=():Record<VirtualAction,number>=>({fold:0,check:0,call:0,raise:0,all_in:0});
function sample(p:VirtualPersonality,position:VirtualPosition,history:PublicPokerAction[],callBb:number,n=2600){
 const unopened=history.length===0&&callBb===0,legalActions:VirtualAction[]=unopened?(position==="big_blind"?["check","raise"]:["fold","raise"]):["fold","call","raise","all_in"];
 const counts=empty();for(let i=0;i<n;i++){const c=context({botHoleCards:hand(i),position,publicActionHistory:history,callAmount:callBb*10,currentBet:callBb*10,legalActions,decisionIndex:i,opponentsStillInHand:Math.max(1,history.length+1)});counts[decideVirtualBotAction(c,p).action]++;}return Object.fromEntries(Object.entries(counts).map(([k,v])=>[k,+(v/n).toFixed(4)]));
}
for(const p of personalities){
 console.log(`\n${p.toUpperCase()} UNOPENED`);
 for(const pos of positions){const r=sample(p,pos,[],0);console.log(pos,{fold:r.fold,freeCheck:r.check,limp:0,openRaise:r.raise,voluntaryEnter:r.raise+r.all_in});}
 console.log(`${p.toUpperCase()} LIMPED`,{oneLimper:sample(p,"button",[{playerId:"x",street:"preflop",action:"call",amount:10}],1),threeLimpers:sample(p,"button",[1,2,3].map(i=>({playerId:`x${i}`,street:"preflop",action:"call",amount:10})),1)});
 for(const bb of [2,2.5,3,5])console.log(`${p.toUpperCase()} FACING_OPEN_${bb}BB`,sample(p,"button",[{playerId:"x",street:"preflop",action:"raise",amount:bb*10}],bb));
 console.log(`${p.toUpperCase()} FACING_RERAISE`,sample(p,"button",[{playerId:"x",street:"preflop",action:"raise",amount:25},{playerId:"y",street:"preflop",action:"raise",amount:80}],8));
}
