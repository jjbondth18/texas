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
  },
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
assert.equal(admin.player_count >= 1, true, "human profile count remains available");

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
const destroyedVirtualPlayerId = virtualSeat.playerId;
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

const emptyRoom = enabledManager.createRoom({ isPublic: true, tableType: "public_chip" });
await delay(50);
assert.equal(emptyRoom.table.seats.some((seat) => seat.serverManagedVirtual), false, "rooms without humans must not receive virtual players");

console.log("Public virtual player tests passed.");

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function lastMessage(messages: Array<Record<string, any>>, type: string): Record<string, any> | undefined {
  return messages.slice().reverse().find((message) => message.type === type);
}
