import { performance } from "node:perf_hooks";
import { context } from "./virtual_player_ai_test.js";
import { decideVirtualBotAction } from "./virtual_player_ai/virtual_ai_policy.js";
const samples:number[]=[],streets=["preflop","flop","turn","river"] as const,opponents=[1,2,4] as const;
const board=[{rank:"2",suit:"C",code:"2C"},{rank:"7",suit:"D",code:"7D"},{rank:"J",suit:"H",code:"JH"},{rank:"4",suit:"S",code:"4S"},{rank:"9",suit:"C",code:"9C"}] as const;
for(let i=0;i<100_000;i++){const street=streets[i%4],count=street==="preflop"?0:street==="flop"?3:street==="turn"?4:5;const c=context({street,communityCards:board.slice(0,count),decisionIndex:i,opponentsStillInHand:opponents[i%3]});const start=performance.now();decideVirtualBotAction(c,(["safe","balanced","active"] as const)[i%3]);samples.push(performance.now()-start);}
samples.sort((a,b)=>a-b);const avg=samples.reduce((a,b)=>a+b,0)/samples.length;console.log(JSON.stringify({runs:samples.length,averageMs:avg,p95Ms:samples[Math.floor(samples.length*.95)],maxMs:samples.at(-1),stable:true},null,2));if(avg>=1)throw new Error(`average ${avg}ms exceeds target`);
