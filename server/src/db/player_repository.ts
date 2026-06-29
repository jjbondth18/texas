import type Database from "better-sqlite3";

export interface PlayerProfileRecord {
  player_id: string;
  display_name: string;
  avatar_id: string;
  created_at: string;
  updated_at: string;
  last_login_at: string | null;
}

export class PlayerRepository {
  constructor(private readonly db: Database.Database) {}

  find(playerId: string): PlayerProfileRecord | undefined {
    return this.db.prepare("SELECT * FROM players WHERE player_id = ?").get(playerId) as PlayerProfileRecord | undefined;
  }

  upsert(playerId: string, displayName: string, avatarId: string, now = new Date().toISOString()): PlayerProfileRecord {
    const existing = this.find(playerId);
    if (!existing) {
      this.db
        .prepare(
          "INSERT INTO players (player_id, display_name, avatar_id, created_at, updated_at, last_login_at) VALUES (?, ?, ?, ?, ?, ?)",
        )
        .run(playerId, displayName, avatarId, now, now, now);
      return this.find(playerId)!;
    }
    this.db
      .prepare("UPDATE players SET display_name = ?, avatar_id = ?, updated_at = ?, last_login_at = ? WHERE player_id = ?")
      .run(displayName, avatarId, now, now, playerId);
    return this.find(playerId)!;
  }

  setAvatar(playerId: string, avatarId: string, now = new Date().toISOString()): PlayerProfileRecord {
    this.db.prepare("UPDATE players SET avatar_id = ?, updated_at = ? WHERE player_id = ?").run(avatarId, now, playerId);
    const profile = this.find(playerId);
    if (!profile) throw new Error("player not found");
    return profile;
  }

  count(): number {
    const row = this.db.prepare("SELECT COUNT(*) AS count FROM players").get() as { count: number } | undefined;
    return Number(row?.count ?? 0);
  }
}
