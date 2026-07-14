import type Database from "better-sqlite3";

export const migration009ReplayEconomy = {
  id: "009_replay_economy",
  up(db: Database.Database): void {
    const columns = db.prepare("PRAGMA table_info(replay_index)").all() as Array<{ name: string }>;
    if (!columns.some((column) => column.name === "replay_type")) {
      db.exec("ALTER TABLE replay_index ADD COLUMN replay_type TEXT NOT NULL DEFAULT 'official_human'");
    }
    db.exec(`
      UPDATE replay_index
      SET replay_type = CASE
        WHEN table_type LIKE 'private_%' THEN 'room_replay'
        ELSE 'official_human'
      END
      WHERE replay_type IS NULL OR replay_type = '' OR replay_type = 'official_human';
    `);
  },
};
