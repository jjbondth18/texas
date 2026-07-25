import assert from "node:assert/strict";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { RoomManager as RoomManagerType } from "./room_manager.js";

process.env.TEXAS_DB_PATH = join(mkdtempSync(join(tmpdir(), "texas-virtual-players-")), "test.sqlite");
const { RoomManager } = await import("./room_manager.js");

class FakeWs {
  OPEN = 1;
  readyState = 1;
  sent: Array<Record<string, any>> = [];
  send(payload: string): void {
    this.sent.push(JSON.parse(payload));
  }
}

function connectHuman(manager: RoomManagerType, id: string): { ws: FakeWs; playerId: string } {
  const ws = new FakeWs();
  const client = manager.connect(ws as any);
  manager.handle(client.id, { type: "hello", auth_provider: "local_dev", external_id: id, player_id: id, name: id });
  return { ws, playerId: id };
}

const disabledManager = new RoomManager({ publicVirtualPlayers: { enabled: false, joinDelayMinMs: 0, joinDelayMaxMs: 0 } });
const disabledHuman = connectHuman(disabledManager, `virtual_test_disabled_${Date.now()}`);
const disabledRoom = disabledManager.createRoom({ isPublic: true, tableType: "public_chip" });
disabledManager.handle(disabledHuman.playerId, { type: "join_room", room_id: disabledRoom.id });
disabledRoom.table.sitDown({ id: disabledHuman.playerId, name: "Disabled Human", connected: true }, 5, 2_000);
disabledManager.handle(disabledHuman.playerId, { type: "ready", room_id: disabledRoom.id, ready: true });
await delay(50);
assert.equal(disabledRoom.table.seats.some((seat) => seat.serverManagedVirtual), false, "disabled switch must prevent allocation");

const enabledManager = new RoomManager({
  publicVirtualPlayers: {
    enabled: true,
    targetOnline: 2,
    maximumOnline: 2,
    maximumPerRoom: 1,
    joinDelayMinMs: 0,
    joinDelayMaxMs: 0,
    actionDelayMinMs: 100,
    actionDelayMaxMs: 100,
    sessionHandMin: 1,
    sessionHandMax: 1,
  },
});
const warmupManager = new RoomManager({
  publicVirtualPlayers: { enabled: true, targetOnline: 1, maximumOnline: 1, maximumPerRoom: 1, joinDelayMinMs: 0, joinDelayMaxMs: 0 },
});
const twoHumanManager = new RoomManager({
  publicVirtualPlayers: { enabled: true, targetOnline: 1, maximumOnline: 1, maximumPerRoom: 1, joinDelayMinMs: 100, joinDelayMaxMs: 100 },
});
const joinedVirtualManager = new RoomManager({
  publicVirtualPlayers: {
    enabled: true,
    targetOnline: 2,
    maximumOnline: 2,
    maximumPerRoom: 1,
    joinDelayMinMs: 0,
    joinDelayMaxMs: 0,
    sessionHandMin: 8,
    sessionHandMax: 8,
  },
});
const waitingCycleManager = new RoomManager({
  publicVirtualPlayers: { enabled: true, targetOnline: 0, maximumOnline: 1, maximumPerRoom: 1 },
});
const human = connectHuman(enabledManager, `virtual_test_human_${Date.now()}`);
enabledManager.handle(human.playerId, { type: "create_table", is_public: true, table_type: "public_chip", buy_in: 2000, small_blind: 25, big_blind: 50, hand_count: 10, max_players: 6 });
const roomId = String(lastMessage(human.ws.sent, "table_created")?.room_id ?? "");
assert(roomId, "human should create an existing public room");
enabledManager.handle(human.playerId, { type: "sit_down", room_id: roomId, seat_index: -1 });
await delay(200);

const room = enabledManager.getRoom(roomId);
assert(room, "public room should exist");
const virtualSeat = room.table.seats.find((seat) => seat.serverManagedVirtual);
assert(virtualSeat, `enabled manager should add one virtual player to a public room with a human: ${JSON.stringify(enabledManager.adminSnapshot(false))}`);
assert.match(virtualSeat.playerId, /^virtual:vp_\d{3}$/);
assert.equal(virtualSeat.ready, true, "virtual player should use normal ready state");
assert.equal(virtualSeat.isAi, false, "public virtual identity must not reuse client-visible AI identity");
assert.equal(enabledManager.getClient(virtualSeat.playerId), undefined, "virtual player must not create a WebSocket client or Steam identity");

const ordinarySnapshot = lastMessage(human.ws.sent, "table_snapshot")?.snapshot;
const publicVirtualSeat = ordinarySnapshot?.seats?.find((seat: any) => seat.player_id === virtualSeat.playerId);
assert(publicVirtualSeat, "ordinary table snapshot should render the virtual player as a normal occupied seat");
assert.equal("player_kind" in publicVirtualSeat, false, "backend player kind must not leak to ordinary protocol");
assert.equal("server_managed_virtual" in publicVirtualSeat, false, "backend virtual marker must not leak to ordinary protocol");
assert.equal(publicVirtualSeat.is_ai, false, "ordinary client must not receive an AI marker for public virtual players");

const admin = enabledManager.adminSnapshot(false) as any;
assert.equal(admin.virtual_online, 1);
assert.equal(admin.human_online, 1);
assert.equal(admin.virtual_players[0].player_kind, "virtual");
assert.equal(Number.isInteger(admin.virtual_players[0].session_hand_target), true, "admin profile snapshot must expose session_hand_target");
assert.equal(admin.virtual_players[0].session_hand_target > 0, true, "seated virtual profile must have a positive session hand target");
assert.equal(admin.player_count >= 1, true, "human profile count remains available");
const virtualState = enabledManager.virtualAdminState() as any;
assert.equal(virtualState.config.maximum_per_room, 1);
assert.equal(virtualState.profiles[0].session_hand_target, admin.virtual_players[0].session_hand_target);
assert.equal(Array.isArray(virtualState.recent_events), true);
assert.equal(Array.isArray(virtualState.filled_rooms), true);

enabledManager.handle(human.playerId, { type: "ready", room_id: roomId, ready: true });
await delay(3_200);
let actionGuard = 0;
while (room.table.phase !== "hand_over" && actionGuard < 80) {
  actionGuard += 1;
  if (room.table.currentTurnSeat === room.table.getSeatByPlayer(human.playerId)?.seatIndex) {
    const privateSnapshot = lastMessage(human.ws.sent, "private_snapshot")?.snapshot;
    const legal = privateSnapshot?.legal_actions ?? [];
    const action = legal.find((item: any) => item.action === "check")
      ?? legal.find((item: any) => item.action === "call")
      ?? legal.find((item: any) => item.action === "fold");
    assert(action, "human test driver should have a legal action");
    enabledManager.handle(human.playerId, { type: "player_action", room_id: roomId, action: action.action, amount: action.amount });
  }
  await delay(125);
}
assert.equal(room.table.phase, "hand_over", "human and virtual player should finish a complete authoritative hand");
assert(room.table.recentActions.some((entry) => entry.player_name === virtualSeat.name), "virtual actions should appear in the shared authoritative action log");
const completingVirtualPlayerId = virtualSeat.playerId;
assert.equal(
  (enabledManager.adminSnapshot(false) as any).virtual_players.find((agent: any) => agent.virtual_player_id === completingVirtualPlayerId)?.virtual_state,
  "seated",
  "virtual player must remain seated before reaching its profile session target",
);
(enabledManager as any).virtualPlayers.markHandCompleted(completingVirtualPlayerId, room.table.handId + 1, virtualSeat.chips);
(enabledManager as any).virtualPlayers.markHandCompleted(completingVirtualPlayerId, room.table.handId + 2, virtualSeat.chips);
(enabledManager as any).virtualPlayers.updateConfig({ targetOnline: 0 });
(enabledManager as any).reconcilePublicVirtualPlayers(room);
assert.equal(room.table.seats.some((seat) => seat.playerId === completingVirtualPlayerId), false, "virtual player should leave safely after reaching its session hand target");
assert.equal(
  (enabledManager.adminSnapshot(false) as any).virtual_players.find((agent: any) => agent.virtual_player_id === completingVirtualPlayerId)?.virtual_state,
  "offline",
  "session hand target should complete the natural lifecycle",
);
const destroyedVirtualPlayerId = completingVirtualPlayerId;
assert.equal(enabledManager.destroyRoom(roomId, "integration_cleanup"), true, "room destruction should use the lifecycle cleanup contract");
assert.equal(enabledManager.getRoom(roomId), undefined);
assert.equal(
  (enabledManager.adminSnapshot(false) as any).virtual_players.find((agent: any) => agent.virtual_player_id === destroyedVirtualPlayerId)?.virtual_state,
  "offline",
  "room destruction must release profile occupancy",
);

enabledManager.updateVirtualPlayerConfig({ joinDelayMinMs: 150, joinDelayMaxMs: 150, targetOnline: 1, maximumOnline: 1 });
const cancellationRoom = enabledManager.createRoom({ isPublic: true, tableType: "public_chip" });
enabledManager.handle(human.playerId, { type: "join_room", room_id: cancellationRoom.id });
cancellationRoom.table.sitDown({ id: human.playerId, name: "Priority Human", connected: true }, 5, 2_000);
enabledManager.handle(human.playerId, { type: "ready", room_id: cancellationRoom.id, ready: true });
await delay(25);
const waitingHuman = connectHuman(enabledManager, `virtual_waiting_human_${Date.now()}`);
enabledManager.handle(waitingHuman.playerId, { type: "join_room", room_id: cancellationRoom.id });
await delay(250);
assert.equal(cancellationRoom.table.seats.some((seat) => seat.serverManagedVirtual), false, "a waiting human must cancel an already scheduled virtual join");

const warmupHuman = connectHuman(warmupManager, `virtual_warmup_human_${Date.now()}`);
warmupManager.handle(warmupHuman.playerId, { type: "create_table", is_public: true, table_type: "public_chip", buy_in: 2000, small_blind: 25, big_blind: 50, hand_count: 10, max_players: 6 });
const warmupRoomId = String(lastMessage(warmupHuman.ws.sent, "table_created")?.room_id ?? "");
warmupManager.handle(warmupHuman.playerId, { type: "sit_down", room_id: warmupRoomId, seat_index: -1 });
warmupManager.handle(warmupHuman.playerId, { type: "start_ai_warmup", room_id: warmupRoomId });
await delay(100);
const warmupRoom = warmupManager.getRoom(warmupRoomId);
assert(warmupRoom?.hostInLocalWarmup, "test room should be in local warmup");
assert(warmupRoom.table.seats.some((seat) => seat.serverManagedVirtual), "one human in local warmup must be eligible for a virtual player");

const firstHuman = connectHuman(twoHumanManager, `virtual_two_humans_a_${Date.now()}`);
const secondHuman = connectHuman(twoHumanManager, `virtual_two_humans_b_${Date.now()}`);
const twoHumanRoom = twoHumanManager.createRoom({ isPublic: true, tableType: "public_chip" });
twoHumanManager.handle(firstHuman.playerId, { type: "join_room", room_id: twoHumanRoom.id });
twoHumanManager.handle(firstHuman.playerId, { type: "sit_down", room_id: twoHumanRoom.id, seat_index: -1 });
twoHumanManager.handle(secondHuman.playerId, { type: "join_room", room_id: twoHumanRoom.id });
twoHumanManager.handle(secondHuman.playerId, { type: "sit_down", room_id: twoHumanRoom.id, seat_index: -1 });
await delay(200);
assert.equal(twoHumanRoom.table.seats.some((seat) => seat.serverManagedVirtual), false, "two seated humans must not receive a new virtual player");

const joinedFirstHuman = connectHuman(joinedVirtualManager, `virtual_joined_a_${Date.now()}`);
const joinedSecondHuman = connectHuman(joinedVirtualManager, `virtual_joined_b_${Date.now()}`);
const joinedRoom = joinedVirtualManager.createRoom({ isPublic: true, tableType: "public_chip" });
joinedVirtualManager.handle(joinedFirstHuman.playerId, { type: "join_room", room_id: joinedRoom.id });
joinedVirtualManager.handle(joinedFirstHuman.playerId, { type: "sit_down", room_id: joinedRoom.id, seat_index: -1 });
await delay(100);
const joinedVirtualSeat = joinedRoom.table.seats.find((seat) => seat.serverManagedVirtual);
assert(joinedVirtualSeat, "one-human room should receive exactly one virtual player");
const joinedVirtualPlayerId = joinedVirtualSeat.playerId;
await delay(100);
assert.equal(joinedRoom.table.seats.filter((seat) => seat.serverManagedVirtual).length, 1, "one human plus one virtual must not receive a second virtual");
joinedVirtualManager.handle(joinedSecondHuman.playerId, { type: "join_room", room_id: joinedRoom.id });
joinedVirtualManager.handle(joinedSecondHuman.playerId, { type: "sit_down", room_id: joinedRoom.id, seat_index: -1 });
await delay(50);
assert(joinedRoom.table.getSeatByPlayer(joinedVirtualSeat.playerId), "second human joining must not evict the seated virtual player");
const joinedAgent = (joinedVirtualManager.adminSnapshot(false) as any).virtual_players.find((agent: any) => agent.virtual_player_id === joinedVirtualPlayerId);
assert.notEqual(joinedAgent?.virtual_state, "pending_leave", "human population growth must not mark a seated virtual player pending leave");
assert.notEqual(joinedAgent?.pending_leave_reason, "human_priority");
assert.notEqual(joinedAgent?.pending_leave_reason, "above_desired");
joinedVirtualManager.requestVirtualPlayerOffline(joinedVirtualPlayerId);
assert.equal(joinedRoom.table.seats.some((seat) => seat.playerId === joinedVirtualPlayerId), false, "admin safe offline must still remove a virtual player at a safe node");

const warmupVirtualPlayerId = warmupRoom.table.seats.find((seat) => seat.serverManagedVirtual)?.playerId ?? "";
assert(warmupVirtualPlayerId);
warmupManager.setVirtualProfileEnabled(warmupVirtualPlayerId, false);
assert.equal(warmupRoom.table.seats.some((seat) => seat.playerId === warmupVirtualPlayerId), false, "profile disable must still perform safe offline");

const cycleHumanA = connectHuman(waitingCycleManager, `virtual_cycle_a_${Date.now()}`);
const cycleHumanB = connectHuman(waitingCycleManager, `virtual_cycle_b_${Date.now()}`);
const cycleRoom = waitingCycleManager.createRoom({ isPublic: true, tableType: "public_chip" });
waitingCycleManager.handle(cycleHumanA.playerId, { type: "join_room", room_id: cycleRoom.id });
cycleRoom.table.sitDown({ id: cycleHumanA.playerId, name: "Cycle A", connected: true }, 5, 2_000);
(waitingCycleManager as any).runVirtualScheduler();
const firstWaitingSince = cycleRoom.singleHumanWaitingSinceAt;
assert(firstWaitingSince, "first single-human waiting period should be recorded");
cycleRoom.singleHumanWaitingSinceAt = "2000-01-01T00:00:00.000Z";
waitingCycleManager.handle(cycleHumanB.playerId, { type: "join_room", room_id: cycleRoom.id });
cycleRoom.table.sitDown({ id: cycleHumanB.playerId, name: "Cycle B", connected: true }, 8, 2_000);
(waitingCycleManager as any).runVirtualScheduler();
assert.equal(cycleRoom.singleHumanWaitingSinceAt, undefined, "two humans should clear the current waiting period");
cycleRoom.table.leaveSeat(cycleHumanB.playerId);
(waitingCycleManager as any).runVirtualScheduler();
assert(cycleRoom.singleHumanWaitingSinceAt);
assert.notEqual(cycleRoom.singleHumanWaitingSinceAt, "2000-01-01T00:00:00.000Z", "a new one-human period must not inherit the old timestamp");

const emptyRoom = enabledManager.createRoom({ isPublic: true, tableType: "public_chip" });
await delay(50);
assert.equal(emptyRoom.table.seats.some((seat) => seat.serverManagedVirtual), false, "rooms without humans must not receive virtual players");

warmupManager.shutdown();
twoHumanManager.shutdown();
joinedVirtualManager.shutdown();
waitingCycleManager.shutdown();
disabledManager.shutdown();
enabledManager.shutdown();

console.log("Public virtual player tests passed.");

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function lastMessage(messages: Array<Record<string, any>>, type: string): Record<string, any> | undefined {
  return messages.slice().reverse().find((message) => message.type === type);
}
