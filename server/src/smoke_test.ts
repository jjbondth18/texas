import { WebSocket, WebSocketServer } from "ws";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ClientMessage, ServerMessage, TableSnapshot } from "./protocol.js";
import { RoomManager } from "./room_manager.js";

interface TestClient {
  name: string;
  ws: WebSocket;
  playerId: string;
  roomId: string;
  messages: ServerMessage[];
}

const port = 18080;
process.env.TEXAS_DB_PATH = join(mkdtempSync(join(tmpdir(), "texas-smoke-")), "texas_dev.sqlite");
const manager = new RoomManager();
const wss = new WebSocketServer({ host: "127.0.0.1", port });

wss.on("connection", (ws) => {
  const client = manager.connect(ws);
  ws.send(JSON.stringify({ type: "hello", player_id: client.id } satisfies ServerMessage));
  ws.on("message", (raw) => {
    try {
      manager.handle(client.id, JSON.parse(raw.toString()) as ClientMessage);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      ws.send(JSON.stringify({ type: "error", error: errorMessage, error_code: errorMessage } satisfies ServerMessage));
    }
  });
  ws.on("close", () => manager.disconnect(client.id));
});

const clients = await Promise.all([connectClient("Ada"), connectClient("Ben"), connectClient("Cy")]);
const [ada, ben, cy] = clients;

send(ada, { type: "hello", name: "Ada" });
send(ben, { type: "hello", name: "Ben" });
send(cy, { type: "hello", name: "Cy" });

send(ada, { type: "create_room" });
await waitFor(ada, (message) => message.type === "hello" && Boolean(message.room_id));
const roomId = ada.roomId;

send(ben, { type: "join_room", room_id: roomId });
send(cy, { type: "join_room", room_id: roomId });
send(ada, { type: "sit_down", room_id: roomId, seat_index: 0, buy_in: 5000 });
send(ben, { type: "sit_down", room_id: roomId, seat_index: 1, buy_in: 5000 });
send(cy, { type: "sit_down", room_id: roomId, seat_index: 2, buy_in: 1200 });
send(ada, { type: "add_table_chips", room_id: roomId, amount: 4000 });
send(ben, { type: "add_table_chips", room_id: roomId, amount: 4000 });
send(cy, { type: "add_table_chips", room_id: roomId, amount: 200 });
send(ada, { type: "ready", room_id: roomId, ready: true });
send(ben, { type: "ready", room_id: roomId, ready: true });
send(cy, { type: "ready", room_id: roomId, ready: true });

await waitForSnapshot((snapshot) => snapshot.seats.filter((seat) => seat.player_id).length === 3);
const before = new Map(lastSnapshot()!.seats.map((seat) => [seat.seat_index, seat.chips]));

await waitForSnapshot((snapshot) => snapshot.phase === "preflop", 5000);

let guard = 0;
while (lastSnapshot()?.phase !== "hand_over" && guard < 80) {
  guard += 1;
  const snapshot = lastSnapshot();
  if (!snapshot) throw new Error("missing table snapshot");
  const actor = clients.find((client) => privateSeat(client) === snapshot.current_turn_seat);
  if (!actor) throw new Error(`no client for current turn seat ${snapshot.current_turn_seat}`);
  const legal = privateLegalActions(actor);
  const canCheck = legal.some((action) => action.action === "check");
  const call = legal.find((action) => action.action === "call");
  const raise = legal.find((action) => action.action === "raise");
  const bet = legal.find((action) => action.action === "bet");

  if (privateSeat(actor) === 2 && snapshot.phase === "preflop") {
    send(actor, { type: "player_action", room_id: roomId, action: "all_in" });
  } else if (raise && snapshot.phase === "preflop" && privateSeat(actor) === 0 && Number(raise.max_amount) >= Number(raise.min_amount)) {
    send(actor, { type: "player_action", room_id: roomId, action: "raise", amount: Number(raise.min_amount) });
  } else if (bet && snapshot.phase === "flop" && privateSeat(actor) === 1) {
    send(actor, { type: "player_action", room_id: roomId, action: "bet", amount: Math.min(Number(bet.max_amount), 300) });
  } else if (call && Number(call.amount) > 0) {
    send(actor, { type: "player_action", room_id: roomId, action: "call" });
  } else if (canCheck) {
    send(actor, { type: "player_action", room_id: roomId, action: "check" });
  } else {
    send(actor, { type: "player_action", room_id: roomId, action: "fold" });
  }
  await waitForSnapshot((snapshotAfter) => snapshotAfter.hand_id !== snapshot.hand_id || snapshotAfter.phase !== snapshot.phase || snapshotAfter.current_turn_seat !== snapshot.current_turn_seat);
}

const finalSnapshot = lastSnapshot();
if (!finalSnapshot || finalSnapshot.phase !== "hand_over") throw new Error("smoke test did not reach hand_over");
if (!finalSnapshot.last_hand_results || finalSnapshot.last_hand_results.length < 2) throw new Error("missing last hand chip results");
const revealedShowdownSeats = finalSnapshot.seats.filter((seat) => (seat.showdown_cards ?? []).length === 2);
if (revealedShowdownSeats.length < 2) throw new Error("showdown hand_over should reveal live showdown hole cards");

const chipChanges = finalSnapshot.seats
  .filter((seat) => seat.player_id)
  .map((seat) => ({
    seat_index: seat.seat_index,
    name: seat.name,
    before: before.get(seat.seat_index) ?? 0,
    after: seat.chips,
    delta: seat.chips - (before.get(seat.seat_index) ?? 0),
  }));

const handOneDealer = finalSnapshot.dealer_seat;
const handOneSmallBlind = finalSnapshot.small_blind_seat;
const inheritedStacks = new Map(finalSnapshot.seats.map((seat) => [seat.seat_index, seat.chips]));

const nextHandSnapshot = await waitForSnapshot((snapshot) => snapshot.hand_id === finalSnapshot.hand_id + 1 && snapshot.phase === "preflop", 9000);
if (nextHandSnapshot.community_cards.length !== 0) throw new Error("next hand should start with no community cards");
if (nextHandSnapshot.pot <= 0) throw new Error("next hand should post blinds into the pot");
if (nextHandSnapshot.dealer_seat === handOneDealer && nextHandSnapshot.seats.filter((seat) => seat.player_id && seat.chips > 0).length > 2) {
  throw new Error("dealer button did not rotate for the next hand");
}
if (nextHandSnapshot.small_blind_seat === handOneSmallBlind && nextHandSnapshot.seats.filter((seat) => seat.player_id && seat.chips > 0).length > 2) {
  throw new Error("small blind did not rotate for the next hand");
}
for (const seat of nextHandSnapshot.seats.filter((item) => item.player_id)) {
  const previous = inheritedStacks.get(seat.seat_index) ?? 0;
  if (seat.chips > previous) throw new Error(`seat ${seat.seat_index} chips did not inherit previous settlement`);
}

console.log("FINAL_TABLE_SNAPSHOT");
console.log(JSON.stringify(finalSnapshot, null, 2));
console.log("CHIP_CHANGES");
console.log(JSON.stringify(chipChanges, null, 2));
console.log("NEXT_HAND_SNAPSHOT");
console.log(JSON.stringify(nextHandSnapshot, null, 2));

for (const client of clients) client.ws.close();
wss.close();

async function connectClient(name: string): Promise<TestClient> {
  const ws = new WebSocket(`ws://127.0.0.1:${port}`);
  const client: TestClient = { name, ws, playerId: "", roomId: "", messages: [] };
  ws.on("message", (raw) => {
    const message = JSON.parse(raw.toString()) as ServerMessage;
    client.messages.push(message);
    if (message.player_id) client.playerId = message.player_id;
    if (message.room_id) client.roomId = message.room_id;
  });
  await new Promise<void>((resolve, reject) => {
    ws.once("open", resolve);
    ws.once("error", reject);
  });
  await waitFor(client, (message) => message.type === "hello" && Boolean(message.player_id));
  return client;
}

function send(client: TestClient, message: ClientMessage): void {
  client.ws.send(JSON.stringify(message));
}

async function waitFor(client: TestClient, predicate: (message: ServerMessage) => boolean, timeoutMs = 3000): Promise<ServerMessage> {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const found = client.messages.find(predicate);
    if (found) return found;
    await sleep(10);
  }
  throw new Error(`timeout waiting for ${client.name}`);
}

async function waitForSnapshot(predicate: (snapshot: TableSnapshot) => boolean, timeoutMs = 3000): Promise<TableSnapshot> {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const snapshot = lastSnapshot();
    if (snapshot && predicate(snapshot)) return snapshot;
    await sleep(10);
  }
  throw new Error("timeout waiting for table snapshot");
}

function lastSnapshot(): TableSnapshot | null {
  for (const client of clients) {
    for (let i = client.messages.length - 1; i >= 0; i -= 1) {
      const message = client.messages[i];
      if (message.type === "table_snapshot") return message.snapshot as TableSnapshot;
    }
  }
  return null;
}

function privateSeat(client: TestClient): number {
  const latest = latestPrivateSnapshot(client);
  return latest ? Number(latest.seat_index) : -1;
}

function privateLegalActions(client: TestClient): Array<Record<string, unknown>> {
  const latest = latestPrivateSnapshot(client);
  return latest ? (latest.legal_actions as Array<Record<string, unknown>>) : [];
}

function latestPrivateSnapshot(client: TestClient): Record<string, unknown> | null {
  for (let i = client.messages.length - 1; i >= 0; i -= 1) {
    const message = client.messages[i];
    if (message.type === "private_snapshot") return message.snapshot as Record<string, unknown>;
  }
  return null;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
