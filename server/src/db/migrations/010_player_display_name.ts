import type Database from "better-sqlite3";

export const migration010PlayerDisplayName = {
  id: "010_player_display_name",
  up(db: Database.Database): void {
    const columns = db.prepare("PRAGMA table_info(players)").all() as Array<{ name: string }>;
    if (!columns.some((column) => column.name === "steam_persona_name")) {
      db.exec("ALTER TABLE players ADD COLUMN steam_persona_name TEXT");
    }
    if (!columns.some((column) => column.name === "display_name_updated_at")) {
      db.exec("ALTER TABLE players ADD COLUMN display_name_updated_at TEXT");
    }
    db.exec(`
      UPDATE players
      SET steam_persona_name = display_name
      WHERE steam_persona_name IS NULL OR TRIM(steam_persona_name) = '';
    `);
  },
};
