import type Database from "better-sqlite3";
import { randomUUID } from "node:crypto";

export interface PlayerIdentityRecord {
  id: string;
  player_id: string;
  provider: string;
  external_id: string;
  created_at: string;
}

export class IdentityRepository {
  constructor(private readonly db: Database.Database) {}

  findByProviderExternal(provider: string, externalId: string): PlayerIdentityRecord | undefined {
    return this.db.prepare("SELECT * FROM player_identities WHERE provider = ? AND external_id = ?").get(provider, externalId) as
      | PlayerIdentityRecord
      | undefined;
  }

  linkIdentity(playerId: string, provider: string, externalId: string, now = new Date().toISOString()): PlayerIdentityRecord {
    this.db
      .prepare("INSERT OR IGNORE INTO player_identities (id, player_id, provider, external_id, created_at) VALUES (?, ?, ?, ?, ?)")
      .run(randomUUID(), playerId, provider, externalId, now);
    return this.db.prepare("SELECT * FROM player_identities WHERE provider = ? AND external_id = ?").get(provider, externalId) as PlayerIdentityRecord;
  }

  count(): number {
    const row = this.db.prepare("SELECT COUNT(*) AS count FROM player_identities").get() as { count: number } | undefined;
    return Number(row?.count ?? 0);
  }
}
