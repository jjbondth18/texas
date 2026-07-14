import assert from "node:assert/strict";
import { decideChallengeBotAction, buildChallengeContextForTest, card, classifyStartingHand } from "./ai_challenge/ai_challenge_policy.js";

const sameA = decideChallengeBotAction(buildChallengeContextForTest({ sessionSeed: 77 }));
const sameB = decideChallengeBotAction(buildChallengeContextForTest({ sessionSeed: 77 }));
assert.deepEqual(sameA, sameB, "same seed and same state must produce same decision");

const decisions = new Set<string>();
for (let seed = 1; seed <= 500; seed += 1) {
  decisions.add(decideChallengeBotAction(buildChallengeContextForTest({
    sessionSeed: seed,
    botHoleCards: [card("7", "C"), card("2", "D")],
    legalActions: ["fold", "call", "raise", "all_in"],
    callAmount: 20,
  })).action);
}
assert(decisions.size >= 2, "different seeds should allow controlled variation");

const downgraded = decideChallengeBotAction(buildChallengeContextForTest({
  botHoleCards: [card("A", "S"), card("A", "H")],
  legalActions: ["fold", "call"],
  minRaiseTo: null,
  maxRaiseTo: null,
}));
assert.equal(downgraded.action, "call", "illegal raise should downgrade to call");

for (let seed = 1; seed <= 20; seed += 1) {
  const decision = decideChallengeBotAction(buildChallengeContextForTest({ sessionSeed: seed, legalActions: ["fold", "call", "raise", "all_in"], minRaiseTo: 40, maxRaiseTo: 120 }));
  assert(["fold", "call", "raise", "all_in"].includes(decision.action), "bot must return legal action");
  if (decision.action === "raise") {
    assert(Number.isFinite(decision.amount), "raise amount must be finite");
    assert(decision.amount! >= 40 && decision.amount! <= 120, "raise amount must be inside legal bounds");
  }
}

let weakFolds = 0;
for (let seed = 1; seed <= 30; seed += 1) {
  const decision = decideChallengeBotAction(buildChallengeContextForTest({
    sessionSeed: seed,
    botHoleCards: [card("7", "C"), card("2", "D")],
    callAmount: 160,
    pot: 120,
    legalActions: ["fold", "call", "raise", "all_in"],
    minRaiseTo: 320,
    maxRaiseTo: 1000,
  }));
  if (decision.action === "fold") weakFolds += 1;
}
assert(weakFolds >= 20, "weak hands should usually fold versus large bets");

let premiumFolds = 0;
for (let seed = 1; seed <= 30; seed += 1) {
  const decision = decideChallengeBotAction(buildChallengeContextForTest({
    sessionSeed: seed,
    botHoleCards: [card("A", "S"), card("A", "D")],
    callAmount: 20,
    legalActions: ["fold", "call", "raise", "all_in"],
  }));
  if (decision.action === "fold") premiumFolds += 1;
}
assert(premiumFolds <= 1, "premium hands should not frequently fold preflop");

assert.equal(classifyStartingHand([card("A", "S"), card("A", "D")]), "PREMIUM");
assert.equal(classifyStartingHand([card("7", "C"), card("2", "D")]), "TRASH");

const contextKeys = Object.keys(buildChallengeContextForTest());
for (const forbidden of ["playerHoleCards", "deck", "futureBoardCards", "privateSnapshot", "encryptedPlayerPrivateCards"]) {
  assert(!contextKeys.includes(forbidden), `ChallengeBotContext must not expose ${forbidden}`);
}

console.log("AI challenge policy tests passed.");
