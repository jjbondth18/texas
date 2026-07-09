import type { ActionLogEntry, Card } from "./protocol.js";
import type { TableState } from "./table_state.js";
import { createCipheriv, createHash, createHmac, randomBytes } from "node:crypto";

export interface ReplayRoomMeta {
  roomCode?: string;
  mode: "public" | "private" | "training" | "local_warmup";
  tableType: string;
  currency?: "chips" | "gems";
  dealerId?: string;
  maxHands: number;
}

export interface ReplayMetadata {
  replay_id: string;
  hand_id: string;
  room_id: string;
  room_code: string;
  mode: string;
  table_type: string;
  currency: string;
  dealer_id: string;
  created_at: string;
  ended_at: string;
  small_blind: number;
  big_blind: number;
  buy_in?: number;
  hand_number: number;
  max_hands: number;
  player_names: string[];
  seat_indices: number[];
  final_pot: number;
  checksum: string;
  schema_version: number;
  storage_mode: "official_encrypted";
  locked: boolean;
}

export interface ReplayPublicPreview {
  replay_id: string;
  hand_id: string;
  room_id: string;
  room_code: string;
  mode: string;
  table_type: string;
  currency: string;
  dealer_id: string;
  ended_at: string;
  players: Array<{ player_id: string; player_name: string; seat_index: number; ending_stack: number; final_status: string }>;
  community_cards: unknown;
  results: unknown;
}

export interface EncryptedReplayDelivery {
  replay_id: string;
  metadata: ReplayMetadata;
  public_preview: ReplayPublicPreview;
  encrypted_private_blob: string;
  checksum: string;
  key_version: number;
  algorithm: "AES-256-CBC-HMAC-SHA256";
}

function cardCode(card: Card): string {
  return card.code || `${card.rank}${card.suit}`;
}

function timestampMs(value: string | undefined): number {
  if (!value) return Date.now();
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : Date.now();
}

function normalizeAction(action: string | undefined): string {
  const value = (action ?? "").toLowerCase();
  if (value === "small_blind" || value === "big_blind") return value;
  if (value === "timeout_check") return "timeout_auto_check";
  if (value === "timeout_fold") return "timeout_auto_fold";
  return value;
}

function actionToReplay(table: TableState, entry: ActionLogEntry): Record<string, unknown> {
  const actorSeat = entry.seat_index ?? entry.seat_id ?? -1;
  const seat = actorSeat >= 0 ? table.getSeat(actorSeat) : undefined;
  return {
    seq: entry.sequence,
    street: entry.betting_round,
    actor_seat: actorSeat,
    actor_player_id: seat?.playerId ?? "",
    action: normalizeAction(entry.action),
    amount: entry.amount ?? 0,
    bet_to: entry.amount ?? 0,
    pot_after: entry.pot_after ?? null,
    player_stack_after: entry.player_stack_after ?? null,
    timestamp_ms: timestampMs(entry.created_at),
    message: entry.message,
    type: entry.type,
  };
}

export function buildHandReplayRecord(table: TableState, meta: ReplayRoomMeta): Record<string, unknown> {
  const finalPot = table.winners.reduce((sum, winner) => sum + winner.amount, 0);
  const winners = table.winners.map((winner) => ({
    winner_seat: winner.seat_index,
    winner_player_id: table.getSeat(winner.seat_index)?.playerId ?? "",
    amount_won: winner.amount,
    hand_rank_text: winner.hand_rank ?? "",
    pot_type: "main",
    cards: winner.cards ?? [],
  }));
  const actions = table.handActions.filter((entry) => entry.hand_id === table.handId).map((entry) => actionToReplay(table, entry));
  const firstAction = actions[0] as { timestamp_ms?: number } | undefined;
  const lastAction = actions[actions.length - 1] as { timestamp_ms?: number } | undefined;
  return {
    replay_version: 1,
    hand_id: `hand_${String(table.handId).padStart(6, "0")}`,
    room_id: table.roomId,
    room_code: meta.roomCode ?? "",
    mode: meta.mode,
    table_type: meta.tableType,
    currency: meta.currency ?? (meta.tableType.endsWith("_gem") ? "gems" : "chips"),
    dealer_id: meta.dealerId ?? "",
    started_at: new Date(firstAction?.timestamp_ms ?? Date.now()).toISOString(),
    ended_at: new Date(lastAction?.timestamp_ms ?? Date.now()).toISOString(),
    small_blind: table.smallBlind,
    big_blind: table.bigBlind,
    button_seat: table.dealerSeat,
    small_blind_seat: table.smallBlindSeat,
    big_blind_seat: table.bigBlindSeat,
    max_hands: meta.maxHands,
    hand_number: table.handId,
    players: table.seats
      .filter((seat) => seat.playerId !== "")
      .map((seat) => {
        const isWinner = table.winners.some((winner) => winner.seat_index === seat.seatIndex);
        return {
          player_id: seat.playerId,
          player_name: seat.name,
          seat_index: seat.seatIndex,
          avatar_id: seat.avatarId,
          is_ai: seat.isAi,
          is_local_warmup_ai: seat.warmupAi,
          starting_stack: table.handStartChipCount(seat.seatIndex) ?? seat.chips,
          ending_stack: seat.chips,
          hole_cards: seat.holeCards.map(cardCode),
          final_status: isWinner ? "winner" : seat.status,
        };
      }),
    community_cards: {
      flop: table.communityCards.slice(0, 3).map(cardCode),
      turn: table.communityCards.slice(3, 4).map(cardCode),
      river: table.communityCards.slice(4, 5).map(cardCode),
    },
    actions,
    results: {
      winners,
      final_pot: finalPot,
      side_pots: table.sidePots().map((pot) => ({ amount: pot.amount, eligible_seats: pot.eligibleSeats })),
      last_hand_results: table.lastHandResults.slice(),
    },
  };
}

export function replayIdFor(table: TableState): string {
  return `${table.roomId}_hand_${String(table.handId).padStart(6, "0")}`.replace(/[^a-zA-Z0-9_-]/g, "_");
}

export function generateReplayKey(): string {
  return randomBytes(32).toString("base64");
}

export function buildEncryptedReplayDelivery(record: Record<string, unknown>, keyMaterial: string): EncryptedReplayDelivery {
  const replayId = String(record.replay_id || replayIdFromRecord(record));
  record.replay_id = replayId;
  const encryptedPrivateBlob = encryptReplayRecord(record, keyMaterial);
  const checksum = createHash("sha256").update(encryptedPrivateBlob, "utf8").digest("hex");
  const metadata = buildReplayMetadata(record, checksum);
  const publicPreview = buildPublicPreview(record);
  return {
    replay_id: replayId,
    metadata,
    public_preview: publicPreview,
    encrypted_private_blob: encryptedPrivateBlob,
    checksum,
    key_version: 1,
    algorithm: "AES-256-CBC-HMAC-SHA256",
  };
}

function encryptReplayRecord(record: Record<string, unknown>, keyMaterial: string): string {
  const key = Buffer.from(keyMaterial, "base64");
  if (key.length !== 32) throw new Error("invalid_replay_key");
  // Godot's AESContext does not provide GCM, so official replay blobs use
  // AES-256-CBC with PKCS#7 padding plus HMAC-SHA256 over iv+ciphertext.
  const encKey = deriveReplaySubkey(key, "texas-replay-enc-v1");
  const macKey = deriveReplaySubkey(key, "texas-replay-mac-v1");
  const iv = randomBytes(16);
  const cipher = createCipheriv("aes-256-cbc", encKey, iv);
  const plaintext = Buffer.from(JSON.stringify(record), "utf8");
  const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const mac = createHmac("sha256", macKey).update(Buffer.concat([iv, ciphertext])).digest();
  return JSON.stringify({
    algorithm: "AES-256-CBC-HMAC-SHA256",
    iv: iv.toString("base64"),
    ciphertext: ciphertext.toString("base64"),
    mac: mac.toString("base64"),
  });
}

function deriveReplaySubkey(rootKey: Buffer, label: string): Buffer {
  return createHmac("sha256", rootKey).update(label, "utf8").digest();
}

function buildReplayMetadata(record: Record<string, unknown>, checksum: string): ReplayMetadata {
  const players = Array.isArray(record.players) ? (record.players as Array<Record<string, unknown>>) : [];
  const results = asRecord(record.results);
  return {
    replay_id: String(record.replay_id || replayIdFromRecord(record)),
    hand_id: String(record.hand_id || ""),
    room_id: String(record.room_id || ""),
    room_code: String(record.room_code || ""),
    mode: String(record.mode || "public"),
    table_type: String(record.table_type || ""),
    currency: String(record.currency || "chips"),
    dealer_id: String(record.dealer_id || ""),
    created_at: String(record.started_at || record.ended_at || new Date().toISOString()),
    ended_at: String(record.ended_at || new Date().toISOString()),
    small_blind: Number(record.small_blind || 0),
    big_blind: Number(record.big_blind || 0),
    hand_number: Number(record.hand_number || 0),
    max_hands: Number(record.max_hands || 0),
    player_names: players.map((player) => String(player.player_name || player.player_id || "")),
    seat_indices: players.map((player) => Number(player.seat_index ?? -1)),
    final_pot: Number(results.final_pot || 0),
    checksum,
    schema_version: Number(record.replay_version || 1),
    storage_mode: "official_encrypted",
    locked: true,
  };
}

function buildPublicPreview(record: Record<string, unknown>): ReplayPublicPreview {
  const players = Array.isArray(record.players) ? (record.players as Array<Record<string, unknown>>) : [];
  return {
    replay_id: String(record.replay_id || replayIdFromRecord(record)),
    hand_id: String(record.hand_id || ""),
    room_id: String(record.room_id || ""),
    room_code: String(record.room_code || ""),
    mode: String(record.mode || "public"),
    table_type: String(record.table_type || ""),
    currency: String(record.currency || "chips"),
    dealer_id: String(record.dealer_id || ""),
    ended_at: String(record.ended_at || new Date().toISOString()),
    players: players.map((player) => ({
      player_id: String(player.player_id || ""),
      player_name: String(player.player_name || ""),
      seat_index: Number(player.seat_index ?? -1),
      ending_stack: Number(player.ending_stack || 0),
      final_status: String(player.final_status || ""),
    })),
    community_cards: record.community_cards ?? {},
    results: record.results ?? {},
  };
}

function replayIdFromRecord(record: Record<string, unknown>): string {
  const roomId = String(record.room_id || "room");
  const handId = String(record.hand_id || "hand_000000");
  return `${roomId}_${handId}`.replace(/[^a-zA-Z0-9_-]/g, "_");
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value) ? (value as Record<string, unknown>) : {};
}
