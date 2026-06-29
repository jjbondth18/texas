import type Database from "better-sqlite3";

export class ResultRepository {
  constructor(private readonly db: Database.Database) {}

  recordHandResult(roomId: string, handId: number | string, playerId: string, chipDelta: number, result: string, now = new Date().toISOString()): void {
    const id = `${roomId}:${handId}:${playerId}`;
    this.db
      .prepare(
        "INSERT OR IGNORE INTO table_session_results (id, room_id, hand_id, player_id, chip_delta, result, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
      )
      .run(id, roomId, String(handId), playerId, Math.floor(chipDelta), result, now);
  }
}
