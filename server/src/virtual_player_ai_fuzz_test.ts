import assert from "node:assert/strict";
import { context } from "./virtual_player_ai_test.js";
import { decideVirtualBotAction } from "./virtual_player_ai/virtual_ai_policy.js";
const personalities=["safe","balanced","active"] as const,streets=["preflop","flop","turn","river"] as const;
const board=[{rank:"2",suit:"C",code:"2C"},{rank:"7",suit:"D",code:"7D"},{rank:"J",suit:"H",code:"JH"},{rank:"4",suit:"S",code:"4S"},{rank:"9",suit:"C",code:"9C"}] as const;
for(let i=0;i<50_000;i++){const street=streets[i%4],count=street==="preflop"?0:street==="flop"?3:street==="turn"?4:5;const c=context({street,communityCards:board.slice(0,count),decisionIndex:i,pot:1+i%1000,callAmount:i%4?i%150:0,opponentsStillInHand:1+i%5});const d=decideVirtualBotAction(c,personalities[i%3]);assert.ok(c.legalActions.includes(d.action));assert.ok(Number.isFinite(d.internalStrength));if(d.action==="raise")assert.ok(Number.isInteger(d.raiseTo)&&d.raiseTo!>=c.minRaiseTo!&&d.raiseTo!<=c.maxRaiseTo!);}
console.log("virtual AI fuzz passed: 50000 decisions");
