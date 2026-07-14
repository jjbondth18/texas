import assert from "node:assert/strict";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";

const root = join(process.cwd(), "..");
const files = walk(root)
  .filter((file) => !file.includes("\\node_modules\\") && !file.includes("\\dist\\") && !file.includes("\\data\\"))
  .filter((file) => file.endsWith(".ts") || file.endsWith(".gd"));

const policyRefs = files
  .map((file) => ({ file: relative(root, file).replaceAll("\\", "/"), source: readFileSync(file, "utf8") }))
  .filter((entry) => entry.source.includes("ai_challenge_policy"));

const allowedPolicyRefs = new Set([
  "server/src/room_manager.ts",
  "server/src/ai_challenge_policy_test.ts",
  "server/src/ai_challenge_performance_test.ts",
  "server/src/ai_challenge_isolation_test.ts",
]);
for (const ref of policyRefs) {
  assert(allowedPolicyRefs.has(ref.file), `Challenge policy must not be imported by ${ref.file}`);
}

const roomManager = read("server/src/room_manager.ts");
assert(roomManager.includes('if (room.mode !== "ai_challenge" || room.sessionComplete) return;'), "bot scheduler must be gated by ai_challenge mode");
assert(roomManager.includes('if (room.mode === "ai_challenge") return this.sitDownAiChallenge'), "challenge sit-down must be isolated");
assert(roomManager.includes('if (room.mode === "ai_challenge") return;'), "formal hand result recording must skip challenge");
assert(roomManager.includes('if (!room.walletImpact) return;'), "wallet/table balance sync must skip no-impact challenge rooms");

const serverBot = read("server/src/bot.ts");
assert(!serverBot.includes("ai_challenge"), "legacy server bot must not know about AI Challenge");
assert(serverBot.includes("function chooseAction"), "legacy bot chooseAction should remain present");

const tableScreen = read("scripts/screens/poker_table_screen.gd");
assert(tableScreen.includes("TableSessionScript.MODE_TRAINING"), "Training path should remain explicit in table screen");
assert(!tableScreen.includes("ai_challenge_policy"), "client must not import Challenge policy");

console.log("AI challenge isolation tests passed.");

function read(path: string): string {
  return readFileSync(join(root, path), "utf8");
}

function walk(dir: string): string[] {
  const result: string[] = [];
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    const stat = statSync(full);
    if (stat.isDirectory()) result.push(...walk(full));
    else result.push(full);
  }
  return result;
}
