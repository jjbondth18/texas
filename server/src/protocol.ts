export type ClientMessageType =
  | "hello"
  | "create_room"
  | "join_room"
  | "sit_down"
  | "leave_seat"
  | "cash_out"
  | "ready"
  | "start_hand"
  | "add_table_chips"
  | "player_action"
  | "get_profile"
  | "get_avatar_catalog"
  | "buy_avatar"
  | "select_avatar"
  | "list_tables"
  | "create_table"
  | "join_table";

export type ServerMessageType =
  | "hello"
  | "sit_down_result"
  | "table_snapshot"
  | "private_snapshot"
  | "profile_snapshot"
  | "wallet_snapshot"
  | "avatar_catalog"
  | "table_list"
  | "table_created"
  | "table_joined"
  | "error";
export type ErrorCode =
  | "insufficient_chips"
  | "insufficient_gems"
  | "not_seated"
  | "invalid_amount"
  | "avatar_not_found"
  | "already_unlocked"
  | "avatar_not_unlocked"
  | "room_not_found"
  | "table_full"
  | "invalid_table_config"
  | "invalid_identity_provider"
  | "cannot_add_chips_during_hand"
  | "cannot_cash_out_during_hand";
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
  player_id?: string;
  auth_provider?: string;
  external_id?: string;
  name?: string;
  player_name?: string;
  avatar_id?: string;
  seat_index?: number;
  buy_in?: number;
  small_blind?: number;
  big_blind?: number;
  hand_count?: number | string;
  max_players?: number;
  is_public?: boolean;
  ready?: boolean;
  action?: PlayerActionType;
  amount?: number;
  table_name?: string;
}

export interface ServerMessage {
  type: ServerMessageType;
  request_id?: string;
  player_id?: string;
  server_player_id?: string;
  room_id?: string;
  error?: string;
  error_code?: ErrorCode | string;
  ok?: boolean;
  seat_index?: number;
  reason?: string;
  snapshot?: unknown;
  profile?: PlayerProfileSnapshot;
  wallet?: WalletSnapshot;
  unlocked_avatar_ids?: string[];
  daily_login_awarded?: boolean;
  awarded_chips?: number;
  warning?: string;
  avatar_catalog?: AvatarCatalogItemSnapshot[];
  tables?: PublicTableSnapshot[];
  table?: PublicTableSnapshot;
}

export interface AvatarCatalogItemSnapshot {
  avatar_id: string;
  display_name: string;
  price_chips: number;
  price_gems: number;
  currency: "chips" | "gems" | "free";
  is_default: boolean;
}

export interface PlayerProfileSnapshot {
  player_id: string;
  display_name: string;
  avatar_id: string;
  created_at: string;
  updated_at: string;
  last_login_at: string | null;
}

export interface WalletSnapshot {
  player_id: string;
  chips: number;
  gems: number;
  updated_at: string;
}

export interface PublicTableSnapshot {
  room_id: string;
  table_name: string;
  small_blind: number;
  big_blind: number;
  buy_in: number;
  hand_count: number;
  max_players: number;
  seated_count: number;
  current_players: number;
  hand_state: Phase;
  is_public: boolean;
  created_at: string;
  seats?: PublicSeatSnapshot[];
}

export interface PublicSeatSnapshot {
  seat_id: number;
  seat_index: number;
  occupied: boolean;
  player_id: string;
  player_name: string;
  name: string;
  avatar_id: string;
  chips: number;
  table_stack: number;
  status: SeatStatus;
  folded: boolean;
  all_in: boolean;
  disconnected: boolean;
  connected: boolean;
  is_ai: boolean;
  warmup_ai: boolean;
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
  event_id: number;
  sequence: number;
  type: "player_action" | "phase" | "winner" | "system";
  hand_id: number;
  phase: Phase;
  betting_round: Phase;
  created_at: string;
  seat_id?: number;
  seat_index?: number;
  player_name?: string;
  action?: string;
  amount?: number;
  message: string;
}

export interface TableSnapshot {
  room_id: string;
  table_info?: PublicTableSnapshot;
  buy_in?: number;
  hand_count?: number;
  seated_count?: number;
  current_players?: number;
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
  last_hand_results: Array<{ seat_index: number; player_name: string; before_chips: number; after_chips: number; delta: number; award: number }>;
  log: string[];
  recent_actions: ActionLogEntry[];
  action_log: ActionLogEntry[];
}

export interface PrivateSnapshot {
  room_id: string;
  player_id: string;
  hand_id: number;
  seat_index: number;
  hole_cards: Card[];
  legal_actions: Array<{ action: PlayerActionType; amount?: number; min_amount?: number; max_amount?: number }>;
}
