import assert from "node:assert/strict";
import type { Card } from "./protocol.js";
import { enforceLegalDecision, decideVirtualBotAction, type VirtualBotContext } from "./virtual_player_ai/virtual_ai_policy.js";
const card=(rank:Card["rank"],suit:Card["suit"]):Card=>({rank,suit,code:`${rank}${suit}`});
export function context(overrides:Partial<VirtualBotContext>={}):VirtualBotContext{return{
 botPlayerId:"virtual-1",botHoleCards:[card("A","S"),card("K","S")],communityCards:[],street:"preflop",pot:30,currentBet:20,callAmount:10,minRaiseTo:40,maxRaiseTo:200,botStack:200,botCommittedThisStreet:10,bigBlind:10,smallBlind:5,seatCount:6,activePlayerCount:4,opponentsStillInHand:3,position:"button",isInPosition:true,legalActions:["fold","call","raise","all_in"],publicActionHistory:[],handIndex:1,decisionIndex:1,sessionSeed:"test",...overrides};}
const a=decideVirtualBotAction(context()),b=decideVirtualBotAction(context());assert.deepEqual(a,b,"same context must reproduce");
assert.ok(context().legalActions.includes(a.action));
const downgraded=enforceLegalDecision(context({legalActions:["call","fold"],minRaiseTo:null,maxRaiseTo:null}),{action:"raise",raiseTo:NaN,internalReason:"postflop_value",internalStrength:.8});assert.equal(downgraded.action,"call");
for(const p of ["safe","balanced","active"] as const){const d=decideVirtualBotAction(context(),p);assert.ok(context().legalActions.includes(d.action));if(d.action==="raise"){assert.ok(Number.isInteger(d.raiseTo));assert.ok(d.raiseTo!>=40&&d.raiseTo!<=200);}}
const strong=decideVirtualBotAction(context({street:"flop",communityCards:[card("A","H"),card("7","D"),card("2","C")],opponentsStillInHand:1,callAmount:10,pot:100}),"balanced");assert.notEqual(strong.action,"fold");
const multi=decideVirtualBotAction(context({botHoleCards:[card("A","S"),card("4","D")],street:"flop",communityCards:[card("A","H"),card("K","H"),card("Q","H")],opponentsStillInHand:4,callAmount:100,pot:100}),"active");assert.equal(multi.action,"fold");
let shortAllIns=0;for(let i=0;i<100;i++)if(decideVirtualBotAction(context({botStack:80,bigBlind:10,botHoleCards:[card("A","S"),card("A","H")],publicActionHistory:[{playerId:"v",street:"preflop",action:"raise",amount:30}],decisionIndex:i}),"safe").action==="all_in")shortAllIns++;assert.ok(shortAllIns>=60);
let lowSprAllIns=0;for(let i=0;i<100;i++)if(decideVirtualBotAction(context({street:"flop",botHoleCards:[card("7","S"),card("7","H")],communityCards:[card("7","D"),card("2","C"),card("K","S")],pot:200,botStack:80,opponentsStillInHand:1,decisionIndex:i}),"balanced").action==="all_in")lowSprAllIns++;assert.ok(lowSprAllIns>=60);
for(let i=0;i<100;i++){assert.notEqual(decideVirtualBotAction(context({street:"flop",botHoleCards:[card("3","S"),card("4","D")],communityCards:[card("A","H"),card("K","C"),card("9","S")],pot:100,botStack:1000,opponentsStillInHand:4,decisionIndex:i}),"active").action,"all_in");assert.notEqual(decideVirtualBotAction(context({street:"flop",botHoleCards:[card("2","S"),card("7","D")],communityCards:[card("7","H"),card("K","C"),card("A","S")],pot:50,botStack:1000,opponentsStillInHand:1,decisionIndex:i}),"active").action,"all_in");}
const illegalAllIn=enforceLegalDecision(context({legalActions:["call","fold"]}),{action:"all_in",internalReason:"postflop_value",internalStrength:.9});assert.equal(illegalAllIn.action,"call");
const keys=Object.keys(context());for(const forbidden of ["deck","futureBoard","room","table","wallet","steamTicket","playerMap","otherHoleCards","operationalTags"])assert.ok(!keys.includes(forbidden));
console.log("virtual AI tests passed");
