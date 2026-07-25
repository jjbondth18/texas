import assert from "node:assert/strict";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import Database from "better-sqlite3";
import { runMigrations } from "./db/migrations.js";
import { VirtualPlayerRepository } from "./db/virtual_player_repository.js";
import { publicVirtualPlayerConfigFromEnv } from "./public_virtual_players.js";
import { VirtualPlayerManager } from "./virtual_player_manager.js";

const database = new Database(join(mkdtempSync(join(tmpdir(), "texas-virtual-lifecycle-")), "test.sqlite"));
database.pragma("foreign_keys = ON");
runMigrations(database);

const repository = new VirtualPlayerRepository(database);
const defaults = {
  ...publicVirtualPlayerConfigFromEnv({}),
  enabled: true,
  targetOnline: 2,
  maximumOnline: 2,
  maximumPerRoom: 1,
  sessionHandMin: 3,
  sessionHandMax: 3,
};
const manager = new VirtualPlayerManager(defaults, repository);

const selected = manager.selectRoom([
  { roomId: "newer", humanCount: 1, virtualCount: 0, waitingHumanCount: 0, availableSeats: 5, effectiveWaitingSinceAt: "2026-01-02T00:00:00.000Z", roomCreatedAt: "2026-01-01T00:00:00.000Z", eligible: true },
  { roomId: "older", humanCount: 1, virtualCount: 0, waitingHumanCount: 0, availableSeats: 5, effectiveWaitingSinceAt: "2026-01-01T00:00:00.000Z", roomCreatedAt: "2026-01-02T00:00:00.000Z", eligible: true },
  { roomId: "blocked", humanCount: 1, virtualCount: 0, waitingHumanCount: 1, availableSeats: 5, effectiveWaitingSinceAt: "2025-01-01T00:00:00.000Z", roomCreatedAt: "2025-01-01T00:00:00.000Z", eligible: true },
]);
assert.equal(selected?.roomId, "older", "global scheduler should prioritize the earliest current waiting period");

const roomAgeFallback = manager.selectRoom([
  { roomId: "new-room", humanCount: 1, virtualCount: 0, waitingHumanCount: 0, availableSeats: 5, effectiveWaitingSinceAt: "2026-01-03T00:00:00.000Z", roomCreatedAt: "2026-01-02T00:00:00.000Z", eligible: true },
  { roomId: "old-room", humanCount: 1, virtualCount: 0, waitingHumanCount: 0, availableSeats: 5, effectiveWaitingSinceAt: "2026-01-03T00:00:00.000Z", roomCreatedAt: "2026-01-01T00:00:00.000Z", eligible: true },
]);
assert.equal(roomAgeFallback?.roomId, "old-room", "room creation time is only the waiting-time tie-break");

const oneHumanOnly = manager.selectRoom([
  { roomId: "two-humans", humanCount: 2, virtualCount: 0, waitingHumanCount: 0, availableSeats: 4, effectiveWaitingSinceAt: "2025-01-01T00:00:00.000Z", roomCreatedAt: "2025-01-01T00:00:00.000Z", eligible: true },
  { roomId: "already-filled", humanCount: 1, virtualCount: 1, waitingHumanCount: 0, availableSeats: 4, effectiveWaitingSinceAt: "2025-01-01T00:00:00.000Z", roomCreatedAt: "2025-01-01T00:00:00.000Z", eligible: true },
]);
assert.equal(oneHumanOnly, undefined, "only exactly one human and zero seated virtual players may be selected");

const first = manager.reserveAgent("older");
const second = manager.reserveAgent("newer");
assert(first && second);
assert.notEqual(first.id, second.id, "one profile cannot be reserved by two rooms");
assert.equal(manager.reserveAgent("third"), undefined, "global online cap includes joining reservations");

manager.releaseReservation(second.id, "test_release");
manager.markSeated(first.id, "older", 8, 2_000);
manager.markPlaying(first.id, 1, 1_975);
manager.markAction(first.id, 1, 1_950, "call");
assert.equal(manager.markHandCompleted(first.id, 1, 2_050), false, "session_hand_min must prevent leaving before the configured target");
assert.equal(manager.markHandCompleted(first.id, 2, 2_100), false, "session_hand_min must still prevent early exit");
assert.equal(manager.markHandCompleted(first.id, 3, 2_150), true, "session hand target must cause pending leave at the configured maximum");
assert.equal(manager.isPendingLeave(first.id), true);
manager.markLeaving(first.id);
manager.markOffline(first.id, "test_complete");

manager.updateConfig({ enabled: false, targetOnline: 1, maximumOnline: 1 });
manager.setProfileEnabled(first.id, false);

const restarted = new VirtualPlayerManager(defaults, new VirtualPlayerRepository(database));
assert.equal(restarted.config().enabled, false, "runtime config must survive restart");
assert.equal(restarted.config().maximumOnline, 1);
assert.equal(restarted.snapshots().find((agent) => agent.playerId === first.id)?.enabled, false, "profile enable override must survive restart");
assert(restarted.logs(50).some((event) => event.event_type === "pending_leave"), "structured lifecycle logs must preserve exit reasons");
assert.equal(restarted.health().status, "ok");

database.close();
console.log("Virtual player lifecycle tests passed.");
