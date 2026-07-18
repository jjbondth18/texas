import type { WalletTransactionRecord } from "./db/wallet_repository.js";

export interface WalletHistoryEntry {
  transaction_id: string;
  currency: "chips" | "gems";
  amount: number;
  balance_after: number;
  reason: string;
  created_at: string;
  reference_id: string;
  room_id: string;
  hand_id: string;
  display_label: string;
}

const REASON_LABELS: Record<string, string> = {
  initial_grant: "Welcome Grant",
  daily_bonus: "Daily Bonus",
  daily_login_bonus_chips: "Daily Bonus",
  daily_login_bonus_gems: "Daily Bonus",
  table_buy_in: "Table Buy-in",
  gem_table_buy_in: "Gem Table Buy-in",
  add_table_chips: "Add Table Chips",
  table_cash_out: "Table Cash Out",
  session_complete_cash_out: "Session Cash Out",
  left_before_official_hand: "Table Buy-in Refund",
  gem_left_before_official_hand: "Gem Buy-in Refund",
  disconnected_cash_out: "Disconnected Cash Out",
  disconnected_grace_expired_cash_out: "Disconnect Recovery",
  server_restart_recovery: "Server Restart Recovery",
  refunded_sit_down_failed: "Buy-in Rollback",
  official_replay_unlock: "Official Replay Unlock",
  room_replay_unlock: "Room Replay Unlock",
  ai_replay_unlock: "AI Replay Unlock",
  training_replay_unlock: "Training Replay Unlock",
  replay_unlock: "Replay Unlock",
  store_mock_purchase: "Internal Test Purchase",
  mock_purchase: "Internal Test Purchase",
  avatar_purchase: "Avatar Purchase",
  ai_challenge_entry: "AI Challenge Entry",
  ai_challenge_entry_fee: "AI Challenge Entry",
  ai_challenge_reward: "AI Challenge Victory",
  ai_challenge_payout: "AI Challenge Reward",
  ai_challenge_entry_refund: "AI Challenge Refund",
  steam_purchase_chips: "Steam Purchase",
  steam_purchase_gems: "Steam Purchase",
  wallet_adjustment: "Wallet Adjustment",
};

export function walletHistoryEntry(transaction: WalletTransactionRecord): WalletHistoryEntry {
  return {
    transaction_id: transaction.id,
    currency: transaction.currency,
    amount: transaction.amount,
    balance_after: transaction.balance_after,
    reason: transaction.reason,
    created_at: transaction.created_at,
    reference_id: transaction.reference_id || transaction.related_hand_id || transaction.related_room_id || "",
    room_id: transaction.related_room_id || "",
    hand_id: transaction.related_hand_id || "",
    display_label: transaction.display_label || REASON_LABELS[transaction.reason] || humanizeReason(transaction.reason),
  };
}

function humanizeReason(reason: string): string {
  const words = reason
    .split("_")
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1));
  return words.join(" ") || "Wallet Activity";
}
