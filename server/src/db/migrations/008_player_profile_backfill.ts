import type Database from "better-sqlite3";

export const migration008PlayerProfileBackfill = {
  id: "008_player_profile_backfill",
  up(db: Database.Database): void {
    db.exec(`
      INSERT OR IGNORE INTO player_progression (player_id, total_xp, level, title_id, created_at, updated_at)
      SELECT player_id, 0, 1, 'new_player', COALESCE(created_at, datetime('now')), datetime('now')
      FROM players;

      INSERT OR IGNORE INTO player_statistics (player_id, hands_played, hands_won, chips_won, gems_won, created_at, updated_at)
      SELECT player_id, 0, 0, 0, 0, COALESCE(created_at, datetime('now')), datetime('now')
      FROM players;
    `);
  },
};
