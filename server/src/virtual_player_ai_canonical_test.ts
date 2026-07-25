import assert from "node:assert/strict";
import type { Card } from "./protocol.js";
import { context } from "./virtual_player_ai_test.js";
import { decideVirtualBotAction } from "./virtual_player_ai/virtual_ai_policy.js";
const C=(rank:Card["rank"],suit:Card["suit"]):Card=>({rank,suit,code:rank+suit});
const positions=["early","middle","cutoff","button","small_blind","big_blind"] as const,pressures=[0,1,2] as const,stacks=[80,400,1000] as const;
const scenarios=[];for(const position of positions)for(const pressure of pressures)for(const botStack of stacks)scenarios.push({position,pressure,botStack});
assert.equal(scenarios.length,54);
const totals={safe:{fold:0,call:0,raise:0,all_in:0,check:0},balanced:{fold:0,call:0,raise:0,all_in:0,check:0},active:{fold:0,call:0,raise:0,all_in:0,check:0}};
for(const s of scenarios)for(const p of ["safe","balanced","active"] as const)for(let seed=0;seed<20;seed++){const history=s.pressure===0?[]:s.pressure===1?[{playerId:"x",street:"preflop" as const,action:"raise" as const,amount:25}]:[{playerId:"x",street:"preflop" as const,action:"raise" as const,amount:25},{playerId:"y",street:"preflop" as const,action:"raise" as const,amount:80}];const d=decideVirtualBotAction(context({botHoleCards:seed%2?[C("A","S"),C("Q","S")]:[C("8","S"),C("7","S")],position:s.position,botStack:s.botStack,publicActionHistory:history,callAmount:s.pressure===0?0:s.pressure===1?25:80,decisionIndex:seed}),p);totals[p][d.action]++;}
assert.ok(totals.safe.raise<=totals.balanced.raise&&totals.balanced.raise<=totals.active.raise);
assert.ok(totals.active.call<=totals.safe.call*1.25+10,"active must not become loose-passive");
console.log("canonical scenarios passed",totals);
