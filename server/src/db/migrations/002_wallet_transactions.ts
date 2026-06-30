import type Database from "better-sqlite3";

export const migration002WalletTransactions = {
  id: "002_wallet_transactions",
  up(db: Database.Database): void {
    db.exec(`
      CREATE TABLE IF NOT EXISTS wallet_transactions (
        id TEXT PRIMARY KEY,
        player_id TEXT NOT NULL,
        currency TEXT NOT NULL,
        amount INTEGER NOT NULL,
        reason TEXT NOT NULL,
        balance_after INTEGER NOT NULL,
        related_room_id TEXT,
        related_hand_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(player_id) REFERENCES players(player_id)
      );

      CREATE INDEX IF NOT EXISTS idx_wallet_transactions_player_created
        ON wallet_transactions(player_id, created_at);
    `);
  },
};
