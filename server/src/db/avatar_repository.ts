import type Database from "better-sqlite3";

export class AvatarRepository {
  constructor(private readonly db: Database.Database) {}

  getUnlockedAvatars(playerId: string): string[] {
    const rows = this.db.prepare("SELECT avatar_id FROM avatar_unlocks WHERE player_id = ? ORDER BY avatar_id").all(playerId) as Array<{ avatar_id: string }>;
    return rows.map((row) => row.avatar_id);
  }

  unlockAvatar(playerId: string, avatarId: string, now = new Date().toISOString()): void {
    this.db
      .prepare("INSERT OR IGNORE INTO avatar_unlocks (player_id, avatar_id, unlocked_at) VALUES (?, ?, ?)")
      .run(playerId, avatarId, now);
  }

  hasAvatar(playerId: string, avatarId: string): boolean {
    const row = this.db.prepare("SELECT 1 AS found FROM avatar_unlocks WHERE player_id = ? AND avatar_id = ?").get(playerId, avatarId);
    return Boolean(row);
  }

  countUnlocks(): number {
    const row = this.db.prepare("SELECT COUNT(*) AS count FROM avatar_unlocks").get() as { count: number } | undefined;
    return Number(row?.count ?? 0);
  }
}
