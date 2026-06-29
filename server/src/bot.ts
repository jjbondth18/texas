import { WebSocket } from "ws";
import type { ClientMessage, PlayerActionType, PrivateSnapshot, ServerMessage, TableSnapshot } from "./protocol.js";

interface BotOptions {
  url: string;
  roomId: string;
  count: number;
  startSeat: number;
  buyIn: number;
}

interface BotState {
  index: number;
  name: string;
  seat: number;
  ws: WebSocket;
  playerId: string;
  roomId: string;
  table: TableSnapshot | null;
  priv: PrivateSnapshot | null;
  createRoomRequested: boolean;
  setupDone: boolean;
  lastActionKey: string;
}

const options = parseArgs(process.argv.slice(2));
const bots: BotState[] = [];
let sharedRoomId = options.roomId;

console.log(`[bot] connecting ${options.count} bot(s) to ${options.url}`);
if (options.roomId) console.log(`[bot] target room ${options.roomId}`);
else console.log("[bot] no --room provided; first bot will create a local room");

for (let i = 0; i < options.count; i += 1) {
  const bot = await connectBot(i);
  bots.push(bot);
}

process.on("SIGINT", () => {
  console.log("\n[bot] shutting down");
  for (const bot of bots) bot.ws.close();
  process.exit(0);
});

async function connectBot(index: number): Promise<BotState> {
  const bot: BotState = {
    index,
    name: `LocalBot${index + 1}`,
    seat: options.startSeat + index,
    ws: new WebSocket(options.url),
    playerId: "",
    roomId: "",
    table: null,
    priv: null,
    createRoomRequested: false,
    setupDone: false,
    lastActionKey: "",
  };

  bot.ws.on("message", (raw) => handleMessage(bot, JSON.parse(raw.toString()) as ServerMessage));
  bot.ws.on("close", () => console.log(`[${bot.name}] disconnected`));
  bot.ws.on("error", (error) => console.log(`[${bot.name}] websocket error: ${error.message}`));

  await new Promise<void>((resolve, reject) => {
    bot.ws.once("open", resolve);
    bot.ws.once("error", reject);
  });

  console.log(`[${bot.name}] connected; seat=${bot.seat}`);
  send(bot, { type: "hello", name: bot.name });
  return bot;
}

function handleMessage(bot: BotState, message: ServerMessage): void {
  if (message.type === "error") {
    console.log(`[${bot.name}] server error: ${message.error}`);
    return;
  }
  if (message.type === "hello") {
    if (message.player_id) bot.playerId = message.player_id;
    if (message.room_id) {
      bot.roomId = message.room_id;
      sharedRoomId = message.room_id;
    }
    console.log(`[${bot.name}] hello player_id=${bot.playerId || "-"} room=${bot.roomId || sharedRoomId || "-"}`);
    afterHello(bot);
    return;
  }
  if (message.type === "table_snapshot") {
    bot.table = message.snapshot as TableSnapshot;
    if (message.room_id) bot.roomId = message.room_id;
    maybeAct(bot);
    return;
  }
  if (message.type === "private_snapshot") {
    bot.priv = message.snapshot as PrivateSnapshot;
    bot.roomId = bot.priv.room_id || bot.roomId;
    maybeAct(bot);
  }
}

function afterHello(bot: BotState): void {
  if (bot.setupDone) return;
  if (bot.index === 0 && !options.roomId && !sharedRoomId) {
    if (bot.createRoomRequested) return;
    bot.createRoomRequested = true;
    console.log(`[${bot.name}] creating room`);
    send(bot, { type: "create_room" });
    return;
  }
  const roomId = sharedRoomId || options.roomId;
  if (!roomId) return;
  joinSitReady(bot, roomId);
}

function joinSitReady(bot: BotState, roomId: string): void {
  if (bot.setupDone) return;
  bot.setupDone = true;
  bot.roomId = roomId;
  console.log(`[${bot.name}] joining room=${roomId}`);
  send(bot, { type: "join_room", room_id: roomId });
  console.log(`[${bot.name}] sitting seat=${bot.seat}`);
  send(bot, { type: "sit_down", room_id: roomId, seat_index: bot.seat, buy_in: options.buyIn });
  console.log(`[${bot.name}] ready`);
  send(bot, { type: "ready", room_id: roomId, ready: true });

  for (const other of bots) {
    if (other !== bot && other.playerId && !other.roomId) joinSitReady(other, roomId);
  }
}

function maybeAct(bot: BotState): void {
  if (!bot.table || !bot.priv) return;
  if (bot.table.current_turn_seat !== bot.priv.seat_index) return;
  if (!["preflop", "flop", "turn", "river"].includes(bot.table.phase)) return;
  const key = `${bot.table.hand_id}:${bot.table.phase}:${bot.table.current_turn_seat}:${JSON.stringify(bot.priv.legal_actions)}`;
  if (bot.lastActionKey === key) return;

  const action = chooseAction(bot.priv);
  if (!action) {
    console.log(`[${bot.name}] no legal check/call/fold action available`);
    return;
  }
  bot.lastActionKey = key;
  const message: ClientMessage = {
    type: "player_action",
    room_id: bot.roomId || bot.priv.room_id,
    action: action.action,
  };
  if (action.amount && action.amount > 0) message.amount = action.amount;
  console.log(`[${bot.name}] action=${action.action}${message.amount ? ` amount=${message.amount}` : ""} seat=${bot.priv.seat_index}`);
  send(bot, message);
}

function chooseAction(priv: PrivateSnapshot): { action: PlayerActionType; amount?: number } | null {
  const check = priv.legal_actions.find((item) => item.action === "check");
  if (check) return { action: "check" };
  const call = priv.legal_actions.find((item) => item.action === "call" && Number(item.amount ?? 0) >= 0);
  if (call) return { action: "call" };
  const fold = priv.legal_actions.find((item) => item.action === "fold");
  if (fold) return { action: "fold" };
  return null;
}

function send(bot: BotState, message: ClientMessage): void {
  if (bot.ws.readyState !== WebSocket.OPEN) {
    console.log(`[${bot.name}] cannot send ${message.type}; socket is not open`);
    return;
  }
  bot.ws.send(JSON.stringify(message));
}

function parseArgs(args: string[]): BotOptions {
  const parsed: BotOptions = {
    url: "ws://127.0.0.1:8080",
    roomId: "",
    count: 2,
    startSeat: 1,
    buyIn: 5000,
  };
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === "--room") parsed.roomId = valueAfter(args, ++i, "--room");
    else if (arg === "--count") parsed.count = clampInt(valueAfter(args, ++i, "--count"), 1, 5);
    else if (arg === "--start-seat") parsed.startSeat = clampInt(valueAfter(args, ++i, "--start-seat"), 0, 5);
    else if (arg === "--url") parsed.url = valueAfter(args, ++i, "--url");
    else if (arg === "--buy-in") parsed.buyIn = clampInt(valueAfter(args, ++i, "--buy-in"), 1, 1000000);
    else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    }
  }
  if (parsed.startSeat + parsed.count > 6) {
    throw new Error(`seat range exceeds 6-max table: start=${parsed.startSeat} count=${parsed.count}`);
  }
  return parsed;
}

function valueAfter(args: string[], index: number, flag: string): string {
  const value = args[index];
  if (!value || value.startsWith("--")) throw new Error(`${flag} requires a value`);
  return value;
}

function clampInt(value: string, min: number, max: number): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed)) throw new Error(`expected integer, got ${value}`);
  return Math.min(Math.max(parsed, min), max);
}

function printHelp(): void {
  console.log(`Local poker test bots

Usage:
  npm.cmd run bot -- --room <room_id> --count 2 --start-seat 1

Options:
  --room <room_id>       Existing room to join. If omitted, bot 1 creates a room.
  --count <n>            Number of bots to connect. Default: 2.
  --start-seat <n>       First seat index. Default: 1.
  --url <ws_url>         WebSocket URL. Default: ws://127.0.0.1:8080.
  --buy-in <n>           Seat buy-in. Default: 5000.
`);
}
