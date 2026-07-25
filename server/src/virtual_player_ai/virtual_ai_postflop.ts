import { evaluateBestHand } from "../hand_evaluator.js";
import type { Card } from "../protocol.js";
import { MULTIWAY_PENALTY } from "./virtual_ai_config.js";
import type { PostflopAssessment, VirtualBotContext } from "./virtual_ai_types.js";
const V: Record<Card["rank"],number>={"2":2,"3":3,"4":4,"5":5,"6":6,"7":7,"8":8,"9":9,T:10,J:11,Q:12,K:13,A:14};
const BASE=[.13,.43,.68,.77,.84,.89,.94,.975,.99];
export function assessVirtualPostflop(c:VirtualBotContext):PostflopAssessment{
  const cards=[...c.botHoleCards,...c.communityCards], e=evaluateBestHand(cards);
  const board=c.communityCards.map(x=>V[x.rank]).sort((a,b)=>a-b), hole=c.botHoleCards.map(x=>V[x.rank]), boardMax=Math.max(...board);
  const suits=new Map<string,number>(); for(const card of cards)suits.set(card.suit,(suits.get(card.suit)??0)+1);
  const flushDraw=e.category<5&&[...suits.values()].some(n=>n===4);
  const unique=[...new Set(cards.map(x=>V[x.rank]).concat(cards.some(x=>x.rank==="A")?[1]:[]))];
  let openEndedStraightDraw=false,gutshot=false;
  for(let start=1;start<=10;start++){const miss=[0,1,2,3,4].filter(n=>!unique.includes(start+n));if(miss.length===1){if(miss[0]===0||miss[0]===4)openEndedStraightDraw=true;else gutshot=true;}}
  const twoOvercards=e.category===0&&hole.every(r=>r>boardMax),pairPlusDraw=e.category>=1&&(flushDraw||openEndedStraightDraw||gutshot),comboDraw=flushDraw&&(openEndedStraightDraw||gutshot);
  let madeHand:PostflopAssessment["madeHand"];
  if(e.category>=2)madeHand=(["high_card","bottom_pair","two_pair","three_of_a_kind","straight","flush","full_house","four_of_a_kind","straight_flush"] as const)[e.category];
  else if(e.category===0)madeHand="high_card";
  else{const pair=e.tiebreakers[0];if(hole[0]===hole[1]&&pair>boardMax)madeHand="overpair";else if(pair===boardMax)madeHand=Math.max(...hole.filter(r=>r!==pair),0)>=11?"top_pair_strong_kicker":"top_pair_weak_kicker";else madeHand=pair===Math.min(...board)?"bottom_pair":"middle_pair";}
  let strength=BASE[e.category]; if(madeHand==="top_pair_strong_kicker")strength=.62;if(madeHand==="top_pair_weak_kicker")strength=.53;if(madeHand==="overpair")strength=.67;
  if(flushDraw)strength+=.09;if(openEndedStraightDraw)strength+=.075;if(gutshot)strength+=.035;if(twoOvercards)strength+=.04;
  if(e.category<=1)strength-=MULTIWAY_PENALTY[Math.min(5,c.opponentsStillInHand)]??.15;
  const spr=c.botStack/Math.max(1,c.pot);if(spr<2.5&&["top_pair_strong_kicker","overpair"].includes(madeHand))strength+=.05;if(spr>8&&e.category<=1&&c.callAmount>c.pot*.65)strength-=.08;
  const boardSuits=[...new Set(c.communityCards.map(x=>x.suit))].map(s=>c.communityCards.filter(x=>x.suit===s).length),connected=board.length>=3&&Math.max(...board)-Math.min(...board)<=5;
  const boardWetness=Math.min(1,(Math.max(...boardSuits)>=3?.45:Math.max(...boardSuits)===2?.2:0)+(connected?.4:0)+(new Set(board).size<board.length?.15:0));
  return{madeHand,estimatedStrength:Math.max(.05,Math.min(.99,strength)),flushDraw,openEndedStraightDraw,gutshot,twoOvercards,pairPlusDraw,comboDraw,boardWetness};
}
