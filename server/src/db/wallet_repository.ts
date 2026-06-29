import type Database from "better-sqlite3";

export interface WalletRecord {
  player_id: string;
  chips: number;
  gems: number;
  updated_at: string;
}

export class WalletRepository {
  constructor(private readonly db: Database.Database) {}

  ensure(playerId: string, initialChips = 10000, initialGems = 0, now = new Date().toISOString()): WalletRecord {
    this.db
      .prepare("INSERT OR IGNORE INTO wallets (player_id, chips, gems, updated_at) VALUES (?, ?, ?, ?)")
      .run(playerId, initialChips, initialGems, now);
    return this.get(playerId)!;
  }

  get(playerId: string): WalletRecord | undefined {
    return this.db.prepare("SELECT * FROM wallets WHERE player_id = ?").get(playerId) as WalletRecord | undefined;
  }

  addChips(playerId: string, amount: number, now = new Date().toISOString()): WalletRecord {
    this.db.prepare("UPDATE wallets SET chips = chips + ?, updated_at = ? WHERE player_id = ?").run(Math.floor(amount), now, playerId);
    return this.get(playerId)!;
  }

  deductChips(playerId: string, amount: number, now = new Date().toISOString()): WalletRecord {
    const normalized = Math.max(0, Math.floor(amount));
    const wallet = this.get(playerId);
    if (!wallet) throw new Error("wallet not found");
    if (wallet.chips < normalized) throw new Error(`insufficient wallet chips: need ${normalized}, have ${wallet.chips}`);
    this.db.prepare("UPDATE wallets SET chips = chips - ?, updated_at = ? WHERE player_id = ?").run(normalized, now, playerId);
    return this.get(playerId)!;
  }

  deductGems(playerId: string, amount: number, now = new Date().toISOString()): WalletRecord {
    const normalized = Math.max(0, Math.floor(amount));
    const wallet = this.get(playerId);
    if (!wallet) throw new Error("wallet not found");
    if (wallet.gems < normalized) throw new Error("insufficient_gems");
    this.db.prepare("UPDATE wallets SET gems = gems - ?, updated_at = ? WHERE player_id = ?").run(normalized, now, playerId);
    return this.get(playerId)!;
  }

  refundTableChips(playerId: string, amount: number, now = new Date().toISOString()): WalletRecord {
    return this.addChips(playerId, Math.max(0, Math.floor(amount)), now);
  }

  totalChips(): number {
    const row = this.db.prepare("SELECT COALESCE(SUM(chips), 0) AS total FROM wallets").get() as { total: number } | undefined;
    return Number(row?.total ?? 0);
  }

  totalGems(): number {
    const row = this.db.prepare("SELECT COALESCE(SUM(gems), 0) AS total FROM wallets").get() as { total: number } | undefined;
    return Number(row?.total ?? 0);
  }
}
