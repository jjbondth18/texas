import type Database from "better-sqlite3";

export const migration006PlayerProfileBootstrap = {
  id: "006_player_profile_bootstrap",
  up(db: Database.Database): void {
    db.exec(`
      CREATE TABLE IF NOT EXISTS player_progression (
        player_id TEXT PRIMARY KEY,
        total_xp INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        title_id TEXT NOT NULL DEFAULT 'new_player',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(player_id) REFERENCES players(player_id)
      );

      CREATE TABLE IF NOT EXISTS player_statistics (
        player_id TEXT PRIMARY KEY,
        hands_played INTEGER NOT NULL DEFAULT 0,
        hands_won INTEGER NOT NULL DEFAULT 0,
        chips_won INTEGER NOT NULL DEFAULT 0,
        gems_won INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(player_id) REFERENCES players(player_id)
      );
    `);
  },
};
