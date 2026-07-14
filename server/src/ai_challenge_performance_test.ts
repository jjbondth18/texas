import assert from "node:assert/strict";
import { performance } from "node:perf_hooks";
import { estimatePostflopEquity } from "./ai_challenge/ai_challenge_equity.js";
import { buildChallengeContextForTest, card, decideChallengeBotAction } from "./ai_challenge/ai_challenge_policy.js";
import { CHALLENGE_SESSION_CONFIGS } from "./ai_challenge/ai_challenge_config.js";
import type { ChallengeId } from "./ai_challenge/ai_challenge_types.js";

type PerfRow = { challengeId: ChallengeId; street: string; avgMs: number; maxMs: number; avgSamples: number; timedOut: number };

function measureStreet(challengeId: ChallengeId, street: "preflop" | "flop" | "turn" | "river"): PerfRow {
  const elapsed: number[] = [];
  const samples: number[] = [];
  let timedOut = 0;
  const config = CHALLENGE_SESSION_CONFIGS[challengeId];
  for (let i = 0; i < 100; i += 1) {
    const communityCards =
      street === "preflop" ? [] :
      street === "flop" ? [card("2", "C"), card("7", "D"), card("J", "H")] :
      street === "turn" ? [card("2", "C"), card("7", "D"), card("J", "H"), card("4", "S")] :
      [card("2", "C"), card("7", "D"), card("J", "H"), card("4", "S"), card("9", "C")];
    const started = performance.now();
    const decision = decideChallengeBotAction(buildChallengeContextForTest({
      street,
      communityCards,
      sessionSeed: 1000 + i,
      decisionIndex: i + 1,
      botTuning: config.bot,
      legalActions: ["fold", "check", "bet", "all_in"],
      callAmount: 0,
      minRaiseTo: 40,
      maxRaiseTo: 1000,
    }));
    elapsed.push(performance.now() - started);
    if (decision.samples !== undefined) samples.push(decision.samples);
    if (decision.timedOut) timedOut += 1;
  }
  return {
    challengeId,
    street,
    avgMs: avg(elapsed),
    maxMs: Math.max(...elapsed),
    avgSamples: samples.length > 0 ? avg(samples) : 0,
    timedOut,
  };
}

const rows = (["rookie", "sharp", "boss"] as const).flatMap((challengeId) => [
  measureStreet(challengeId, "preflop"),
  measureStreet(challengeId, "flop"),
  measureStreet(challengeId, "turn"),
  measureStreet(challengeId, "river"),
]);
for (const row of rows) {
  assert(Number.isFinite(row.avgMs), `${row.street} avg should be finite`);
  assert(row.maxMs < 250, `${row.street} decision should stay bounded`);
}

const timed = estimatePostflopEquity({
  botHoleCards: [card("A", "S"), card("K", "S")],
  communityCards: [card("Q", "S"), card("J", "S"), card("2", "D")],
  seed: 42,
  tuning: CHALLENGE_SESSION_CONFIGS.boss.bot,
  samples: 240,
  timeBudgetMs: 0,
});
assert(timed.timedOut, "zero-ms soft budget should trigger timeout");
assert(timed.samples > 0, "timeout should still return completed samples");
assert(Number.isFinite(timed.equity), "timeout equity should be finite");

console.log("AI challenge performance rows:");
for (const row of rows) {
  console.log(`${row.challengeId}/${row.street}: avg=${row.avgMs.toFixed(2)}ms max=${row.maxMs.toFixed(2)}ms avgSamples=${row.avgSamples.toFixed(1)} timedOut=${row.timedOut}`);
}
console.log(`timeout probe: samples=${timed.samples} equity=${timed.equity.toFixed(3)} elapsed=${timed.elapsedMs}ms timedOut=${timed.timedOut}`);

function avg(values: number[]): number {
  return values.reduce((sum, value) => sum + value, 0) / Math.max(1, values.length);
}
