import assert from "node:assert/strict";
import { decideChallengeBotAction, buildChallengeContextForTest, card, classifyStartingHand } from "./ai_challenge/ai_challenge_policy.js";
import { estimatePostflopEquity } from "./ai_challenge/ai_challenge_equity.js";
import { CHALLENGE_SESSION_CONFIGS } from "./ai_challenge/ai_challenge_config.js";

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

function rookiePostflop(input: Parameters<typeof buildChallengeContextForTest>[0]) {
  return decideChallengeBotAction(buildChallengeContextForTest({
    street: "flop",
    pot: 120,
    callAmount: 20,
    legalActions: ["fold", "call", "raise", "all_in"],
    minRaiseTo: 40,
    maxRaiseTo: 1000,
    botTuning: CHALLENGE_SESSION_CONFIGS.rookie.bot,
    ...input,
  }));
}

const seededRookieA = rookiePostflop({
  sessionSeed: 909,
  botHoleCards: [card("K", "S"), card("Q", "D")],
  communityCards: [card("Q", "C"), card("7", "H"), card("2", "S")],
});
const seededRookieB = rookiePostflop({
  sessionSeed: 909,
  botHoleCards: [card("K", "S"), card("Q", "D")],
  communityCards: [card("Q", "C"), card("7", "H"), card("2", "S")],
});
assert.deepEqual(seededRookieA, seededRookieB, "Rookie rule fallback must remain reproducible with a fixed seed");
assert.equal(seededRookieA.equitySource, "rule_fallback");
assert.equal(seededRookieA.samples, 0);
assert(Number.isFinite(seededRookieA.equity), "Rookie fallback equity must be finite");

let topPairFolds = 0;
let twoPairOrTripsFolds = 0;
let weakHighCardFolds = 0;
let strongDrawCalls = 0;
for (let seed = 1; seed <= 100; seed += 1) {
  const topPair = rookiePostflop({
    sessionSeed: seed,
    botHoleCards: [card("K", "S"), card("Q", "D")],
    communityCards: [card("Q", "C"), card("7", "H"), card("2", "S")],
  });
  if (topPair.action === "fold") topPairFolds += 1;

  for (const strongMade of [
    { botHoleCards: [card("K", "S"), card("7", "D")], communityCards: [card("K", "C"), card("7", "H"), card("2", "S")] },
    { botHoleCards: [card("7", "S"), card("7", "D")], communityCards: [card("7", "C"), card("Q", "H"), card("2", "S")] },
  ]) {
    const decision = rookiePostflop({ sessionSeed: seed, ...strongMade });
    if (decision.action === "fold") twoPairOrTripsFolds += 1;
  }

  const weakHigh = rookiePostflop({
    sessionSeed: seed,
    botHoleCards: [card("8", "C"), card("3", "D")],
    communityCards: [card("A", "S"), card("K", "H"), card("6", "C")],
    pot: 100,
    callAmount: 120,
    minRaiseTo: 240,
  });
  if (weakHigh.action === "fold") weakHighCardFolds += 1;

  const strongDraw = rookiePostflop({
    sessionSeed: seed,
    botHoleCards: [card("A", "H"), card("9", "H")],
    communityCards: [card("K", "H"), card("7", "H"), card("2", "C")],
  });
  if (strongDraw.action === "call") strongDrawCalls += 1;
}
assert(topPairFolds <= 5, "Rookie top pair should not fold frequently versus a small bet");
assert.equal(twoPairOrTripsFolds, 0, "Rookie two pair and trips must not fold to a small bet");
assert(weakHighCardFolds >= 80, "Rookie weak high card should mostly fold versus an oversized bet");
assert(strongDrawCalls >= 30, "Rookie strong draws should have a reproducible, reasonable call frequency versus a small bet");

const disabledEquity = estimatePostflopEquity({
  botHoleCards: [card("A", "S"), card("K", "S")],
  communityCards: [card("Q", "S"), card("J", "S"), card("2", "D")],
  seed: 1,
  samples: 0,
});
assert.deepEqual(disabledEquity, { equity: 0.5, samples: 0, elapsedMs: 0, timedOut: false, source: "disabled" }, "0 samples must return before the Monte Carlo loop");
assert(Number.isFinite(disabledEquity.equity), "0 samples must never produce NaN");

for (const difficulty of ["sharp", "boss"] as const) {
  const decision = decideChallengeBotAction(buildChallengeContextForTest({
    street: "flop",
    botHoleCards: [card("A", "S"), card("K", "S")],
    communityCards: [card("Q", "S"), card("J", "H"), card("2", "D")],
    botTuning: CHALLENGE_SESSION_CONFIGS[difficulty].bot,
  }));
  assert.equal(decision.equitySource, "monte_carlo", `${difficulty} must keep the Monte Carlo equity path`);
  assert((decision.samples ?? 0) > 0, `${difficulty} must complete equity samples`);
  assert(Number.isFinite(decision.equity), `${difficulty} equity must be finite`);
}

const contextKeys = Object.keys(buildChallengeContextForTest());
for (const forbidden of ["playerHoleCards", "deck", "futureBoardCards", "privateSnapshot", "encryptedPlayerPrivateCards"]) {
  assert(!contextKeys.includes(forbidden), `ChallengeBotContext must not expose ${forbidden}`);
}

console.log("AI challenge policy tests passed.");
