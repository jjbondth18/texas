export type ClientMessageType =
  | "hello"
  | "create_room"
  | "join_room"
  | "sit_down"
  | "leave_seat"
  | "cash_out"
  | "ready"
  | "restart_session"
  | "start_hand"
  | "start_ai_warmup"
  | "dev_simulate_real_join"
  | "add_table_chips"
  | "player_action"
  | "get_profile"
  | "rename_display_name"
  | "get_avatar_catalog"
  | "claim_daily_bonus"
  | "buy_avatar"
  | "select_avatar"
  | "mock_purchase"
  | "unlock_replay"
  | "list_tables"
  | "quick_join_table"
  | "create_table"
  | "join_table"
  | "create_private_table"
  | "join_private_table";

export type ServerMessageType =
  | "hello"
  | "sit_down_result"
  | "table_snapshot"
  | "private_snapshot"
  | "profile_snapshot"
  | "wallet_snapshot"
  | "daily_bonus_result"
  | "avatar_catalog"
  | "table_list"
  | "quick_table_matched"
  | "table_created"
  | "table_joined"
  | "private_table_created"
  | "private_table_joined"
  | "mock_purchase_result"
  | "replay_unlocked"
  | "start_ai_warmup_result"
  | "error";
export type ErrorCode =
  | "insufficient_chips"
  | "insufficient_gems"
  | "not_seated"
  | "invalid_amount"
  | "avatar_not_found"
  | "already_unlocked"
  | "avatar_not_unlocked"
  | "replay_not_found"
  | "replay_access_denied"
  | "replay_key_missing"
  | "replay_unlock_failed"
  | "invalid_replay_type"
  | "room_not_found"
  | "room_not_available"
  | "table_full"
  | "invalid_table_config"
  | "invalid_identity_provider"
  | "steam_ticket_required"
  | "steam_ticket_invalid"
  | "steam_app_mismatch"
  | "steam_identity_mismatch"
  | "invalid_display_name"
  | "display_name_reserved"
  | "display_name_prohibited"
  | "display_name_cooldown"
  | "mock_purchase_disabled"
  | "not_public_table"
  | "not_host"
  | "not_enough_players"
  | "not_ready_to_start"
  | "already_playing"
  | "not_waiting"
  | "too_many_real_players"
  | "cannot_add_chips_during_hand"
  | "cannot_cash_out_during_hand";
export type PlayerActionType = "fold" | "check" | "call" | "bet" | "raise" | "all_in";
export type Phase = "waiting" | "preflop" | "flop" | "turn" | "river" | "showdown" | "hand_over" | "session_complete";
export type SeatStatus = "empty" | "sitting" | "ready" | "playing" | "folded" | "all_in" | "sit_out" | "waiting_next_hand" | "disconnected";
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
  steam_auth_ticket?: string;
  steam_auth_identity?: string;
  name?: string;
  player_name?: string;
  display_name?: string;
  avatar_id?: string;
  seat_index?: number;
  buy_in?: number;
  small_blind?: number;
  big_blind?: number;
  hand_count?: number | string;
  action_time_seconds?: number;
  max_players?: number;
  is_public?: boolean;
  ready?: boolean;
  action?: PlayerActionType;
  amount?: number;
  table_name?: string;
  table_type?: string;
  currency?: "chips" | "gems";
  source?: string;
  room_code?: string;
  replay_id?: string;
  replay_type?: "official_human" | "room_replay" | "ai" | "training";
}

export interface ServerMessage {
  type: ServerMessageType;
  request_id?: string;
  player_id?: string;
  server_player_id?: string;
  room_id?: string;
  reconnected_to_table?: boolean;
  error?: string;
  error_code?: ErrorCode | string;
  ok?: boolean;
  seat_index?: number;
  reason?: string;
  wallet_chips?: number;
  required_chips?: number;
  snapshot?: unknown;
  profile?: PlayerProfileSnapshot;
  profile_snapshot?: ServerProfileSnapshot;
  wallet?: WalletSnapshot;
  unlocked_avatar_ids?: string[];
  daily_login_awarded?: boolean;
  awarded_chips?: number;
  awarded_xp?: number;
  awarded_gems?: number;
  daily_bonus_day?: number;
  daily_bonus_status?: DailyBonusStatusSnapshot;
  is_new_player?: boolean;
  warning?: string;
  avatar_catalog?: AvatarCatalogItemSnapshot[];
  tables?: PublicTableSnapshot[];
  table?: PublicTableSnapshot;
  currency?: "chips" | "gems";
  amount?: number;
  source?: string;
  replay_id?: string;
  replay_key?: string;
  key_version?: number;
  checksum?: string;
  already_unlocked?: boolean;
  replay_type?: "official_human" | "room_replay" | "ai" | "training";
  price_gems?: number;
  is_ai_warmup?: boolean;
  local_warmup?: boolean;
  host_in_local_warmup?: boolean;
}

export interface DailyBonusStatusSnapshot {
  current_day: number;
  cycle_day: number;
  can_claim_today: boolean;
  already_claimed_today: boolean;
  claim_count: number;
  claimed_days_in_cycle: number;
  claim_date: string;
  rewards: Array<{ day: number; chips: number; xp: number; gems: number }>;
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
  steam_persona_name: string | null;
  display_name_updated_at: string | null;
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

export interface ServerProfileSnapshot {
  player_id: string;
  display_name: string;
  steam_persona_name: string;
  steam_id: string;
  display_name_updated_at: string | null;
  is_new_player?: boolean;
  avatar_id: string;
  wallet: {
    chips: number;
    gems: number;
  };
  progression: {
    total_xp: number;
    level: number;
    title_id: string;
  };
  statistics: {
    hands_played: number;
    hands_won: number;
    chips_won: number;
    gems_won: number;
  };
  unlocked_avatar_ids: string[];
  daily_bonus: DailyBonusStatusSnapshot;
  replay_economy: {
    currency: "gems";
    prices: {
      official_human: number;
      room_replay: number;
      ai: number;
      training: number;
    };
  };
  created_at: string;
  updated_at: string;
}

export interface PublicTableSnapshot {
  room_id: string;
  table_type?: string;
  currency?: string;
  allow_quick_join?: boolean;
  room_code?: string;
  visibility?: string;
  table_name: string;
  dealer_id?: string;
  small_blind: number;
  big_blind: number;
  buy_in: number;
  hand_count: number;
  action_time_seconds?: number;
  max_hands?: number;
  hands_played?: number;
  current_hand_number?: number;
  session_complete?: boolean;
  max_players: number;
  seated_count: number;
  current_players: number;
  hand_state: Phase;
  status?: string;
  table_state?: string;
  room_state?: string;
  is_ai_warmup?: boolean;
  host_in_local_warmup?: boolean;
  host_player_id?: string;
  official_hand_started?: boolean;
  ready_count?: number;
  ready_required_count?: number;
  ready_countdown_deadline_at?: string;
  hand_result_deadline_at?: string;
  action_timeout_ms?: number;
  action_deadline_at?: string;
  dev_simulated_player_present?: boolean;
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
  reconnect_grace_remaining_seconds?: number;
  connected: boolean;
  ready: boolean;
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
  showdown_cards?: Card[];
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
  pot_after?: number;
  player_stack_after?: number;
  message: string;
}

export interface TableSnapshot {
  room_id: string;
  table_info?: PublicTableSnapshot;
  dealer_id?: string;
  buy_in?: number;
  hand_count?: number;
  action_time_seconds?: number;
  max_hands?: number;
  hands_played?: number;
  current_hand_number?: number;
  session_complete?: boolean;
  seated_count?: number;
  current_players?: number;
  hand_state: Phase;
  betting_round: Phase;
  phase: Phase;
  hand_id: number;
  status?: string;
  table_state?: string;
  room_state?: string;
  is_ai_warmup?: boolean;
  host_in_local_warmup?: boolean;
  host_player_id?: string;
  official_hand_started?: boolean;
  ready_count?: number;
  ready_required_count?: number;
  ready_countdown_deadline_at?: string;
  hand_result_deadline_at?: string;
  action_timeout_ms?: number;
  action_deadline_at?: string;
  dev_simulated_player_present?: boolean;
  seats: PublicSeatSnapshot[];
  community_cards: Card[];
  pot: number;
  side_pots: Array<{ amount: number; eligible_seats: number[] }>;
  current_bet: number;
  min_raise_to: number;
  current_turn_seat: number;
  current_turn_player_id?: string;
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
  replay_record?: Record<string, unknown>;
  replay_delivery?: Record<string, unknown>;
}

export interface PrivateSnapshot {
  room_id: string;
  player_id: string;
  hand_id: number;
  seat_index: number;
  hole_cards: Card[];
  legal_actions: Array<{ action: PlayerActionType; amount?: number; min_amount?: number; max_amount?: number }>;
}
