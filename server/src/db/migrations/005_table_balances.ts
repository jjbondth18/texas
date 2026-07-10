import type Database from "better-sqlite3";

export const migration005TableBalances = {
  id: "005_table_balances",
  up(db: Database.Database): void {
    db.exec(`
      CREATE TABLE IF NOT EXISTS table_balances (
        room_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        currency TEXT NOT NULL,
        amount INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY(room_id, player_id)
      );

      CREATE INDEX IF NOT EXISTS idx_table_balances_player
        ON table_balances(player_id);
    `);
  },
};
