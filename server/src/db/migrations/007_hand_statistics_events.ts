import type Database from "better-sqlite3";

export const migration007HandStatisticsEvents = {
  id: "007_hand_statistics_events",
  up(db: Database.Database): void {
    db.exec(`
      CREATE TABLE IF NOT EXISTS hand_statistics_events (
        hand_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        currency TEXT NOT NULL,
        net_delta INTEGER NOT NULL,
        won INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (hand_id, player_id),
        FOREIGN KEY(player_id) REFERENCES players(player_id)
      );
    `);
  },
};
