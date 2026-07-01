import type Database from "better-sqlite3";
import { randomUUID } from "node:crypto";

export interface WalletRecord {
  player_id: string;
  chips: number;
  gems: number;
  updated_at: string;
}

export type WalletCurrency = "chips" | "gems";

export interface WalletAdjustment {
  reason: string;
  relatedRoomId?: string;
  relatedHandId?: string;
  now?: string;
}

export interface WalletTransactionRecord {
  id: string;
  player_id: string;
  currency: WalletCurrency;
  amount: number;
  reason: string;
  balance_after: number;
  related_room_id?: string | null;
  related_hand_id?: string | null;
  created_at: string;
}

export class WalletRepository {
  constructor(private readonly db: Database.Database) {}

  ensure(playerId: string, initialChips = 10000, initialGems = 0, now = new Date().toISOString()): WalletRecord {
    const existing = this.get(playerId);
    if (existing) return existing;
    this.db.transaction(() => {
      this.db.prepare("INSERT INTO wallets (player_id, chips, gems, updated_at) VALUES (?, ?, ?, ?)").run(playerId, initialChips, initialGems, now);
      if (initialChips !== 0) this.insertTransaction(playerId, "chips", initialChips, "initial_grant", initialChips, now);
      if (initialGems !== 0) this.insertTransaction(playerId, "gems", initialGems, "initial_grant", initialGems, now);
    })();
    return this.get(playerId)!;
  }

  get(playerId: string): WalletRecord | undefined {
    return this.db.prepare("SELECT * FROM wallets WHERE player_id = ?").get(playerId) as WalletRecord | undefined;
  }

  addChips(playerId: string, amount: number, nowOrOptions: string | WalletAdjustment = new Date().toISOString()): WalletRecord {
    const options = adjustmentOptions(nowOrOptions, "wallet_adjustment");
    return this.adjustBalance(playerId, "chips", Math.floor(amount), options);
  }

  deductChips(playerId: string, amount: number, nowOrOptions: string | WalletAdjustment = new Date().toISOString()): WalletRecord {
    const options = adjustmentOptions(nowOrOptions, "wallet_adjustment");
    return this.adjustBalance(playerId, "chips", -Math.max(0, Math.floor(amount)), options);
  }

  addGems(playerId: string, amount: number, nowOrOptions: string | WalletAdjustment = new Date().toISOString()): WalletRecord {
    const options = adjustmentOptions(nowOrOptions, "wallet_adjustment");
    return this.adjustBalance(playerId, "gems", Math.floor(amount), options);
  }

  deductGems(playerId: string, amount: number, nowOrOptions: string | WalletAdjustment = new Date().toISOString()): WalletRecord {
    const options = adjustmentOptions(nowOrOptions, "wallet_adjustment");
    return this.adjustBalance(playerId, "gems", -Math.max(0, Math.floor(amount)), options);
  }

  refundTableChips(playerId: string, amount: number, nowOrOptions: string | WalletAdjustment = new Date().toISOString()): WalletRecord {
    const options = adjustmentOptions(nowOrOptions, "table_cash_out");
    return this.addChips(playerId, Math.max(0, Math.floor(amount)), options);
  }

  adjustBalance(playerId: string, currency: WalletCurrency, amount: number, options: WalletAdjustment): WalletRecord {
    const normalized = Math.floor(amount);
    if (normalized === 0) return this.get(playerId) ?? this.ensure(playerId);
    const now = options.now || new Date().toISOString();
    const column = currency === "chips" ? "chips" : "gems";
    const transaction = this.db.transaction(() => {
      const wallet = this.get(playerId);
      if (!wallet) throw new Error("wallet not found");
      const current = Number(wallet[column]);
      const next = current + normalized;
      if (next < 0) throw new Error(currency === "chips" ? "insufficient_chips" : "insufficient_gems");
      this.db.prepare(`UPDATE wallets SET ${column} = ?, updated_at = ? WHERE player_id = ?`).run(next, now, playerId);
      this.insertTransaction(playerId, currency, normalized, options.reason, next, now, options.relatedRoomId, options.relatedHandId);
    });
    transaction();
    return this.get(playerId)!;
  }

  transactionCount(reason?: string): number {
    const row = reason
      ? (this.db.prepare("SELECT COUNT(*) AS count FROM wallet_transactions WHERE reason = ?").get(reason) as { count: number } | undefined)
      : (this.db.prepare("SELECT COUNT(*) AS count FROM wallet_transactions").get() as { count: number } | undefined);
    return Number(row?.count ?? 0);
  }

  transactionsForPlayer(playerId: string, limit = 100): WalletTransactionRecord[] {
    return this.db
      .prepare(
        "SELECT id, player_id, currency, amount, reason, balance_after, related_room_id, related_hand_id, created_at FROM wallet_transactions WHERE player_id = ? ORDER BY created_at DESC LIMIT ?",
      )
      .all(playerId, Math.max(1, Math.floor(limit))) as WalletTransactionRecord[];
  }

  auditWalletTransactions(playerId: string): { unmatchedBuyIns: WalletTransactionRecord[] } {
    const transactions = this.transactionsForPlayer(playerId, 500).slice().reverse();
    const exits = new Set(["left_before_official_hand", "table_cash_out", "session_complete_cash_out", "disconnected_cash_out", "refunded_sit_down_failed"]);
    const unmatchedBuyIns: WalletTransactionRecord[] = [];
    for (const transaction of transactions) {
      if (transaction.reason === "table_buy_in") unmatchedBuyIns.push(transaction);
      if (exits.has(transaction.reason) && transaction.related_room_id) {
        const index = unmatchedBuyIns.findIndex((buyIn) => buyIn.related_room_id === transaction.related_room_id);
        if (index >= 0) unmatchedBuyIns.splice(index, 1);
      }
    }
    return { unmatchedBuyIns };
  }

  totalChips(): number {
    const row = this.db.prepare("SELECT COALESCE(SUM(chips), 0) AS total FROM wallets").get() as { total: number } | undefined;
    return Number(row?.total ?? 0);
  }

  totalGems(): number {
    const row = this.db.prepare("SELECT COALESCE(SUM(gems), 0) AS total FROM wallets").get() as { total: number } | undefined;
    return Number(row?.total ?? 0);
  }

  private insertTransaction(
    playerId: string,
    currency: WalletCurrency,
    amount: number,
    reason: string,
    balanceAfter: number,
    createdAt: string,
    relatedRoomId?: string,
    relatedHandId?: string,
  ): void {
    this.db
      .prepare(
        "INSERT INTO wallet_transactions (id, player_id, currency, amount, reason, balance_after, related_room_id, related_hand_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
      )
      .run(
        randomUUID(),
        playerId,
        currency,
        amount,
        reason,
        balanceAfter,
        relatedRoomId ?? null,
        relatedHandId ?? null,
        createdAt,
      );
  }
}

function adjustmentOptions(value: string | WalletAdjustment, defaultReason: string): WalletAdjustment {
  if (typeof value === "string") return { reason: defaultReason, now: value };
  return { reason: value.reason || defaultReason, relatedRoomId: value.relatedRoomId, relatedHandId: value.relatedHandId, now: value.now };
}
