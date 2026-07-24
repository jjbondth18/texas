import type Database from "better-sqlite3";

export interface PlayerProfileRecord {
  player_id: string;
  display_name: string;
  steam_persona_name: string | null;
  display_name_updated_at: string | null;
  avatar_id: string;
  created_at: string;
  updated_at: string;
  last_login_at: string | null;
}

export const DISPLAY_NAME_RENAME_COOLDOWN_DAYS = 30;
const DISPLAY_NAME_RENAME_COOLDOWN_MS = DISPLAY_NAME_RENAME_COOLDOWN_DAYS * 24 * 60 * 60 * 1000;
const RESERVED_DISPLAY_NAMES = new Set([
  "admin",
  "moderator",
  "system",
  "developer",
  "steam",
  "texas",
  "poker",
  "replay",
  "guest",
]);

function passesProfanityFilter(_displayName: string): boolean {
  // TODO: Replace this hook with the production moderation provider.
  return true;
}

export function normalizeDisplayName(rawDisplayName: string): string {
  if (/[\u0000-\u001f\u007f]/u.test(rawDisplayName)) throw new Error("invalid_display_name");
  const displayName = rawDisplayName.trim().replace(/\s+/gu, " ");
  const length = [...displayName].length;
  if (length < 3 || length > 16) throw new Error("invalid_display_name");
  if (RESERVED_DISPLAY_NAMES.has(displayName.toLocaleLowerCase("en-US"))) throw new Error("display_name_reserved");
  if (!passesProfanityFilter(displayName)) throw new Error("display_name_prohibited");
  return displayName;
}

export class PlayerRepository {
  constructor(private readonly db: Database.Database) {}

  find(playerId: string): PlayerProfileRecord | undefined {
    return this.db.prepare("SELECT * FROM players WHERE player_id = ?").get(playerId) as PlayerProfileRecord | undefined;
  }

  isBanned(playerId: string): boolean {
    const row = this.db.prepare("SELECT is_banned FROM player_admin_state WHERE player_id = ?").get(playerId) as { is_banned: number } | undefined;
    return Number(row?.is_banned ?? 0) === 1;
  }

  upsert(playerId: string, identityName: string, avatarId: string, provider = "local_dev", now = new Date().toISOString()): PlayerProfileRecord {
    const existing = this.find(playerId);
    if (!existing) {
      const steamPersonaName = provider === "steam" ? identityName : null;
      this.db
        .prepare(
          "INSERT INTO players (player_id, display_name, steam_persona_name, avatar_id, created_at, updated_at, last_login_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
        )
        .run(playerId, identityName, steamPersonaName, avatarId, now, now, now);
      return this.find(playerId)!;
    }
    if (provider === "steam") {
      this.db
        .prepare("UPDATE players SET steam_persona_name = ?, avatar_id = ?, updated_at = ?, last_login_at = ? WHERE player_id = ?")
        .run(identityName, avatarId, now, now, playerId);
      return this.find(playerId)!;
    }
    this.db
      .prepare("UPDATE players SET display_name = ?, avatar_id = ?, updated_at = ?, last_login_at = ? WHERE player_id = ?")
      .run(identityName, avatarId, now, now, playerId);
    return this.find(playerId)!;
  }

  renameDisplayName(playerId: string, rawDisplayName: string, now = new Date().toISOString()): PlayerProfileRecord {
    const profile = this.find(playerId);
    if (!profile) throw new Error("player_not_found");
    const nowMs = Date.parse(now);
    const previousRenameMs = profile.display_name_updated_at ? Date.parse(profile.display_name_updated_at) : Number.NaN;
    if (Number.isFinite(previousRenameMs) && nowMs - previousRenameMs < DISPLAY_NAME_RENAME_COOLDOWN_MS) {
      throw new Error("display_name_cooldown");
    }
    const displayName = normalizeDisplayName(rawDisplayName);
    this.db
      .prepare("UPDATE players SET display_name = ?, display_name_updated_at = ?, updated_at = ? WHERE player_id = ?")
      .run(displayName, now, now, playerId);
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
