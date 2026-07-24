import type Database from "better-sqlite3";

export const migration013LocalAdmin = {
  id: "013_local_admin",
  up(db: Database.Database): void {
    db.exec(`
      CREATE TABLE IF NOT EXISTS player_admin_state (
        player_id TEXT PRIMARY KEY,
        is_banned INTEGER NOT NULL DEFAULT 0,
        ban_reason TEXT,
        banned_at TEXT,
        admin_note TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL,
        FOREIGN KEY(player_id) REFERENCES players(player_id)
      );

      CREATE TABLE IF NOT EXISTS admin_audit_logs (
        id TEXT PRIMARY KEY,
        player_id TEXT,
        action_type TEXT NOT NULL,
        currency TEXT,
        value_before INTEGER,
        change_amount INTEGER,
        value_after INTEGER,
        reason TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(player_id) REFERENCES players(player_id)
      );

      CREATE INDEX IF NOT EXISTS idx_admin_audit_created
        ON admin_audit_logs(created_at);
      CREATE INDEX IF NOT EXISTS idx_admin_audit_player_created
        ON admin_audit_logs(player_id, created_at);
    `);
  },
};
