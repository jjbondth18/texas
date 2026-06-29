export type ClientMessageType =
  | "hello"
  | "create_room"
  | "join_room"
  | "sit_down"
  | "leave_seat"
  | "ready"
  | "start_hand"
  | "player_action";

export type ServerMessageType = "hello" | "table_snapshot" | "private_snapshot" | "error";
export type PlayerActionType = "fold" | "check" | "call" | "bet" | "raise" | "all_in";
export type Phase = "waiting" | "preflop" | "flop" | "turn" | "river" | "showdown" | "hand_over";
export type SeatStatus = "empty" | "sitting" | "ready" | "playing" | "folded" | "all_in" | "sit_out" | "disconnected";
export type Suit = "C" | "D" | "H" | "S";
export type Rank = "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "T" | "J" | "Q" | "K" | "A";

export interface Card {
  rank: Rank;
  suit: Suit;
  code: string;
}

export interface ClientMessage {
  type: ClientMessageType;
  request_id?: string;
  room_id?: string;
  name?: string;
  seat_index?: number;
  buy_in?: number;
  ready?: boolean;
  action?: PlayerActionType;
  amount?: number;
}

export interface ServerMessage {
  type: ServerMessageType;
  request_id?: string;
  player_id?: string;
  room_id?: string;
  error?: string;
  snapshot?: unknown;
}

export interface PublicSeatSnapshot {
  seat_id: number;
  seat_index: number;
  player_id: string;
  player_name: string;
  name: string;
  chips: number;
  status: SeatStatus;
  folded: boolean;
  all_in: boolean;
  disconnected: boolean;
  current_bet: number;
  contribution: number;
  last_action: string;
  last_action_amount: number;
  is_dealer: boolean;
  is_small_blind: boolean;
  is_big_blind: boolean;
  hole_card_count: number;
}

export interface ActionLogEntry {
  id: number;
  type: "player_action" | "phase" | "winner" | "system";
  hand_id: number;
  phase: Phase;
  seat_index?: number;
  player_name?: string;
  action?: string;
  amount?: number;
  message: string;
}

export interface TableSnapshot {
  room_id: string;
  hand_state: Phase;
  betting_round: Phase;
  phase: Phase;
  hand_id: number;
  seats: PublicSeatSnapshot[];
  community_cards: Card[];
  pot: number;
  side_pots: Array<{ amount: number; eligible_seats: number[] }>;
  current_bet: number;
  min_raise_to: number;
  current_turn_seat: number;
  dealer_seat: number;
  small_blind_seat: number;
  big_blind_seat: number;
  small_blind: number;
  big_blind: number;
  winners: Array<{ seat_index: number; amount: number; hand_rank?: string; cards?: string[] }>;
  log: string[];
  recent_actions: ActionLogEntry[];
  action_log: ActionLogEntry[];
}

export interface PrivateSnapshot {
  room_id: string;
  player_id: string;
  seat_index: number;
  hole_cards: Card[];
  legal_actions: Array<{ action: PlayerActionType; amount?: number; min_amount?: number; max_amount?: number }>;
}
