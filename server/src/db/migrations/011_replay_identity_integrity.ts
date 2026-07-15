import type Database from "better-sqlite3";

export const migration011ReplayIdentityIntegrity = {
  id: "011_replay_identity_integrity",
  up(db: Database.Database): void {
    const columns = db.prepare("PRAGMA table_info(replay_index)").all() as Array<{ name: string }>;
    if (!columns.some((column) => column.name === "algorithm")) {
      db.exec("ALTER TABLE replay_index ADD COLUMN algorithm TEXT NOT NULL DEFAULT ''");
    }
    if (!columns.some((column) => column.name === "integrity_status")) {
      db.exec("ALTER TABLE replay_index ADD COLUMN integrity_status TEXT NOT NULL DEFAULT 'legacy'");
    }
    db.exec("UPDATE replay_index SET integrity_status = 'legacy' WHERE integrity_status IS NULL OR integrity_status = ''");
  },
};
