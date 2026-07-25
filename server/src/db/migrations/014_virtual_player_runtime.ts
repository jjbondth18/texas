import type Database from "better-sqlite3";

export const migration014VirtualPlayerRuntime = {
  id: "014_virtual_player_runtime",
  up(db: Database.Database): void {
    db.exec(`
      CREATE TABLE IF NOT EXISTS virtual_player_runtime_config (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        config_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS virtual_player_profile_settings (
        virtual_player_id TEXT PRIMARY KEY,
        enabled INTEGER NOT NULL CHECK (enabled IN (0, 1)),
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS virtual_player_runtime_state (
        virtual_player_id TEXT PRIMARY KEY,
        state TEXT NOT NULL,
        room_id TEXT NOT NULL DEFAULT '',
        seat_index INTEGER NOT NULL DEFAULT -1,
        chips INTEGER NOT NULL DEFAULT 0,
        hand_id INTEGER NOT NULL DEFAULT 0,
        session_hands_played INTEGER NOT NULL DEFAULT 0,
        online_since TEXT,
        last_action_at TEXT,
        recent_error TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS virtual_player_runtime_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        virtual_player_id TEXT NOT NULL DEFAULT '',
        room_id TEXT NOT NULL DEFAULT '',
        event_type TEXT NOT NULL,
        detail TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_virtual_player_events_created
        ON virtual_player_runtime_events(created_at DESC);
    `);
  },
};
