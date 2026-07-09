import type Database from "better-sqlite3";

export const migration003ReplayMetadata = {
  id: "003_replay_metadata",
  up(db: Database.Database): void {
    db.exec(`
      CREATE TABLE IF NOT EXISTS replay_index (
        replay_id TEXT PRIMARY KEY,
        hand_id TEXT NOT NULL,
        room_id TEXT NOT NULL,
        room_code TEXT,
        table_type TEXT NOT NULL,
        currency TEXT NOT NULL,
        created_at TEXT NOT NULL,
        checksum TEXT NOT NULL,
        schema_version INTEGER NOT NULL
      );

      CREATE TABLE IF NOT EXISTS replay_participants (
        replay_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        seat_index INTEGER NOT NULL,
        PRIMARY KEY (replay_id, player_id),
        FOREIGN KEY(replay_id) REFERENCES replay_index(replay_id)
      );

      CREATE TABLE IF NOT EXISTS replay_keys (
        replay_id TEXT PRIMARY KEY,
        key_material TEXT NOT NULL,
        key_version INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(replay_id) REFERENCES replay_index(replay_id)
      );
    `);
  },
};
