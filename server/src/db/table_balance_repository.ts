import type Database from "better-sqlite3";

export type TableBalanceCurrency = "chips" | "gems";

export interface TableBalanceRecord {
  room_id: string;
  player_id: string;
  currency: TableBalanceCurrency;
  amount: number;
  created_at: string;
  updated_at: string;
}

export class TableBalanceRepository {
  constructor(private readonly db: Database.Database) {}

  get(roomId: string, playerId: string): TableBalanceRecord | undefined {
    return this.db.prepare("SELECT * FROM table_balances WHERE room_id = ? AND player_id = ?").get(roomId, playerId) as TableBalanceRecord | undefined;
  }

  add(roomId: string, playerId: string, currency: TableBalanceCurrency, amount: number, now = new Date().toISOString()): TableBalanceRecord {
    const normalized = Math.max(0, Math.floor(amount));
    if (normalized <= 0) return this.get(roomId, playerId) ?? this.insert(roomId, playerId, currency, 0, now);
    const existing = this.get(roomId, playerId);
    if (existing && existing.currency !== currency) throw new Error("table_balance_currency_mismatch");
    if (existing) {
      this.db
        .prepare("UPDATE table_balances SET amount = amount + ?, updated_at = ? WHERE room_id = ? AND player_id = ?")
        .run(normalized, now, roomId, playerId);
    } else {
      this.insert(roomId, playerId, currency, normalized, now);
    }
    return this.get(roomId, playerId)!;
  }

  clear(roomId: string, playerId: string): void {
    this.db.prepare("DELETE FROM table_balances WHERE room_id = ? AND player_id = ?").run(roomId, playerId);
  }

  set(roomId: string, playerId: string, currency: TableBalanceCurrency, amount: number, now = new Date().toISOString()): TableBalanceRecord | undefined {
    const normalized = Math.max(0, Math.floor(amount));
    if (normalized <= 0) {
      this.clear(roomId, playerId);
      return undefined;
    }
    const existing = this.get(roomId, playerId);
    if (existing && existing.currency !== currency) throw new Error("table_balance_currency_mismatch");
    if (existing) {
      this.db
        .prepare("UPDATE table_balances SET amount = ?, updated_at = ? WHERE room_id = ? AND player_id = ?")
        .run(normalized, now, roomId, playerId);
    } else {
      this.insert(roomId, playerId, currency, normalized, now);
    }
    return this.get(roomId, playerId);
  }

  allForRoom(roomId: string): TableBalanceRecord[] {
    return this.db.prepare("SELECT * FROM table_balances WHERE room_id = ? ORDER BY updated_at ASC").all(roomId) as TableBalanceRecord[];
  }

  allOutstanding(): TableBalanceRecord[] {
    return this.db.prepare("SELECT * FROM table_balances WHERE amount > 0 ORDER BY updated_at ASC").all() as TableBalanceRecord[];
  }

  totalOutstanding(playerId: string, currency: TableBalanceCurrency): number {
    const row = this.db
      .prepare("SELECT COALESCE(SUM(amount), 0) AS total FROM table_balances WHERE player_id = ? AND currency = ?")
      .get(playerId, currency) as { total: number } | undefined;
    return Number(row?.total ?? 0);
  }

  private insert(roomId: string, playerId: string, currency: TableBalanceCurrency, amount: number, now: string): TableBalanceRecord {
    this.db
      .prepare("INSERT OR REPLACE INTO table_balances (room_id, player_id, currency, amount, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)")
      .run(roomId, playerId, currency, Math.max(0, Math.floor(amount)), now, now);
    return this.get(roomId, playerId)!;
  }
}
