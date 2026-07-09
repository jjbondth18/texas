import type Database from "better-sqlite3";

export interface ReplayIndexRecord {
  replay_id: string;
  hand_id: string;
  room_id: string;
  room_code?: string;
  table_type: string;
  currency: string;
  created_at: string;
  checksum: string;
  schema_version: number;
}

export interface ReplayParticipantRecord {
  replay_id: string;
  player_id: string;
  seat_index: number;
}

export interface ReplayKeyRecord {
  replay_id: string;
  key_material: string;
  key_version: number;
  created_at: string;
}

export interface ReplayUnlockRecord {
  replay_id: string;
  player_id: string;
  currency: string;
  cost: number;
  transaction_id?: string | null;
  unlocked_at: string;
}

export class ReplayRepository {
  constructor(private readonly db: Database.Database) {}

  saveReplayIndex(record: ReplayIndexRecord): void {
    this.db
      .prepare(
        "INSERT OR IGNORE INTO replay_index (replay_id, hand_id, room_id, room_code, table_type, currency, created_at, checksum, schema_version) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
      )
      .run(
        record.replay_id,
        record.hand_id,
        record.room_id,
        record.room_code ?? null,
        record.table_type,
        record.currency,
        record.created_at,
        record.checksum,
        record.schema_version,
      );
  }

  saveParticipants(replayId: string, participants: Array<Omit<ReplayParticipantRecord, "replay_id">>): void {
    const insert = this.db.prepare("INSERT OR IGNORE INTO replay_participants (replay_id, player_id, seat_index) VALUES (?, ?, ?)");
    const transaction = this.db.transaction(() => {
      for (const participant of participants) {
        insert.run(replayId, participant.player_id, Math.floor(participant.seat_index));
      }
    });
    transaction();
  }

  saveReplayKey(record: ReplayKeyRecord): void {
    this.db
      .prepare("INSERT OR IGNORE INTO replay_keys (replay_id, key_material, key_version, created_at) VALUES (?, ?, ?, ?)")
      .run(record.replay_id, record.key_material, Math.floor(record.key_version), record.created_at);
  }

  getReplayIndex(replayId: string): ReplayIndexRecord | undefined {
    return this.db.prepare("SELECT * FROM replay_index WHERE replay_id = ?").get(replayId) as ReplayIndexRecord | undefined;
  }

  getReplayKey(replayId: string): ReplayKeyRecord | undefined {
    return this.db.prepare("SELECT * FROM replay_keys WHERE replay_id = ?").get(replayId) as ReplayKeyRecord | undefined;
  }

  hasReplay(replayId: string): boolean {
    return Boolean(this.getReplayIndex(replayId));
  }

  isParticipant(replayId: string, playerId: string): boolean {
    const row = this.db.prepare("SELECT 1 AS found FROM replay_participants WHERE replay_id = ? AND player_id = ?").get(replayId, playerId);
    return Boolean(row);
  }

  getUnlock(replayId: string, playerId: string): ReplayUnlockRecord | undefined {
    return this.db.prepare("SELECT * FROM replay_unlocks WHERE replay_id = ? AND player_id = ?").get(replayId, playerId) as ReplayUnlockRecord | undefined;
  }

  isUnlocked(replayId: string, playerId: string): boolean {
    return Boolean(this.getUnlock(replayId, playerId));
  }

  recordUnlock(replayId: string, playerId: string, cost: number, currency = "gems", transactionId?: string, unlockedAt = new Date().toISOString()): ReplayUnlockRecord {
    // TODO: Wire transaction_id to wallet_transactions once WalletRepository returns inserted transaction IDs.
    this.db
      .prepare(
        "INSERT OR IGNORE INTO replay_unlocks (replay_id, player_id, currency, cost, transaction_id, unlocked_at) VALUES (?, ?, ?, ?, ?, ?)",
      )
      .run(replayId, playerId, currency, Math.floor(cost), transactionId ?? null, unlockedAt);
    const unlock = this.getUnlock(replayId, playerId);
    if (!unlock) throw new Error("replay_unlock_failed");
    return unlock;
  }
}
