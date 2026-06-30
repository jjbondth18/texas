import type Database from "better-sqlite3";

export const migration001InitialSchema = {
  id: "001_initial_schema",
  up(db: Database.Database): void {
    db.exec(`
      CREATE TABLE IF NOT EXISTS players (
        player_id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        avatar_id TEXT NOT NULL DEFAULT 'default',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_login_at TEXT
      );

      CREATE TABLE IF NOT EXISTS wallets (
        player_id TEXT PRIMARY KEY,
        chips INTEGER NOT NULL DEFAULT 0,
        gems INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(player_id) REFERENCES players(player_id)
      );

      CREATE TABLE IF NOT EXISTS daily_login_claims (
        player_id TEXT NOT NULL,
        claim_date TEXT NOT NULL,
        chips_awarded INTEGER NOT NULL,
        claimed_at TEXT NOT NULL,
        PRIMARY KEY(player_id, claim_date),
        FOREIGN KEY(player_id) REFERENCES players(player_id)
      );

      CREATE TABLE IF NOT EXISTS avatar_unlocks (
        player_id TEXT NOT NULL,
        avatar_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        PRIMARY KEY(player_id, avatar_id),
        FOREIGN KEY(player_id) REFERENCES players(player_id)
      );

      CREATE TABLE IF NOT EXISTS table_session_results (
        id TEXT PRIMARY KEY,
        room_id TEXT,
        hand_id TEXT,
        player_id TEXT NOT NULL,
        chip_delta INTEGER NOT NULL,
        result TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(player_id) REFERENCES players(player_id)
      );

      CREATE TABLE IF NOT EXISTS player_identities (
        id TEXT PRIMARY KEY,
        player_id TEXT NOT NULL,
        provider TEXT NOT NULL,
        external_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(provider, external_id),
        FOREIGN KEY(player_id) REFERENCES players(player_id)
      );
    `);
  },
};
