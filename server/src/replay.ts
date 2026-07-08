import type { ActionLogEntry, Card } from "./protocol.js";
import type { TableState } from "./table_state.js";

export interface ReplayRoomMeta {
  roomCode?: string;
  mode: "public" | "private" | "training" | "local_warmup";
  tableType: string;
  currency?: "chips" | "gems";
  dealerId?: string;
  maxHands: number;
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
