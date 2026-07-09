import type Database from "better-sqlite3";

export const migration004ReplayUnlocks = {
  id: "004_replay_unlocks",
  up(db: Database.Database): void {
    db.exec(`
      CREATE TABLE IF NOT EXISTS replay_unlocks (
        replay_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        currency TEXT NOT NULL,
        cost INTEGER NOT NULL,
        transaction_id TEXT,
        unlocked_at TEXT NOT NULL,
        PRIMARY KEY (replay_id, player_id),
        FOREIGN KEY(replay_id) REFERENCES replay_index(replay_id)
      );
    `);
  },
};
