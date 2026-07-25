import type Database from "better-sqlite3";
import type { PublicVirtualPlayerConfig } from "../public_virtual_players.js";

export type PersistedVirtualPlayerState = {
  virtual_player_id: string;
  state: string;
  room_id: string;
  seat_index: number;
  chips: number;
  hand_id: number;
  session_hands_played: number;
  online_since: string | null;
  last_action_at: string | null;
  recent_error: string;
  updated_at: string;
};

export class VirtualPlayerRepository {
  constructor(private readonly db: Database.Database) {}

  loadConfig(): PublicVirtualPlayerConfig | undefined {
    const row = this.db.prepare("SELECT config_json FROM virtual_player_runtime_config WHERE id = 1").get() as { config_json: string } | undefined;
    if (!row) return undefined;
    try {
      return JSON.parse(row.config_json) as PublicVirtualPlayerConfig;
    } catch {
      return undefined;
    }
  }

  saveConfig(config: PublicVirtualPlayerConfig, now = new Date().toISOString()): void {
    this.db.prepare(`
      INSERT INTO virtual_player_runtime_config (id, config_json, updated_at)
      VALUES (1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET config_json = excluded.config_json, updated_at = excluded.updated_at
    `).run(JSON.stringify(config), now);
  }

  profileOverrides(): Map<string, boolean> {
    const rows = this.db.prepare("SELECT virtual_player_id, enabled FROM virtual_player_profile_settings").all() as Array<{ virtual_player_id: string; enabled: number }>;
    return new Map(rows.map((row) => [row.virtual_player_id, row.enabled === 1]));
  }

  saveProfileEnabled(playerId: string, enabled: boolean, now = new Date().toISOString()): void {
    this.db.prepare(`
      INSERT INTO virtual_player_profile_settings (virtual_player_id, enabled, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(virtual_player_id) DO UPDATE SET enabled = excluded.enabled, updated_at = excluded.updated_at
    `).run(playerId, enabled ? 1 : 0, now);
  }

  saveState(state: Omit<PersistedVirtualPlayerState, "updated_at">, now = new Date().toISOString()): void {
    this.db.prepare(`
      INSERT INTO virtual_player_runtime_state (
        virtual_player_id, state, room_id, seat_index, chips, hand_id,
        session_hands_played, online_since, last_action_at, recent_error, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(virtual_player_id) DO UPDATE SET
        state = excluded.state,
        room_id = excluded.room_id,
        seat_index = excluded.seat_index,
        chips = excluded.chips,
        hand_id = excluded.hand_id,
        session_hands_played = excluded.session_hands_played,
        online_since = excluded.online_since,
        last_action_at = excluded.last_action_at,
        recent_error = excluded.recent_error,
        updated_at = excluded.updated_at
    `).run(
      state.virtual_player_id,
      state.state,
      state.room_id,
      state.seat_index,
      state.chips,
      state.hand_id,
      state.session_hands_played,
      state.online_since,
      state.last_action_at,
      state.recent_error,
      now,
    );
  }

  recoverAfterRestart(now = new Date().toISOString()): number {
    const result = this.db.prepare(`
      UPDATE virtual_player_runtime_state
      SET state = 'offline', room_id = '', seat_index = -1, chips = 0, hand_id = 0,
          online_since = NULL, recent_error = 'server_restart_recovery', updated_at = ?
      WHERE state <> 'offline'
    `).run(now);
    return result.changes;
  }

  appendEvent(eventType: string, playerId = "", roomId = "", detail = "", now = new Date().toISOString()): void {
    this.db.transaction(() => {
      this.db.prepare(`
        INSERT INTO virtual_player_runtime_events (virtual_player_id, room_id, event_type, detail, created_at)
        VALUES (?, ?, ?, ?, ?)
      `).run(playerId, roomId, eventType, detail.slice(0, 1000), now);
      this.db.prepare(`
        DELETE FROM virtual_player_runtime_events
        WHERE id <= (SELECT COALESCE(MAX(id), 0) - 5000 FROM virtual_player_runtime_events)
      `).run();
    })();
  }

  recentEvents(limit = 100): Array<Record<string, unknown>> {
    return this.db.prepare(`
      SELECT virtual_player_id, room_id, event_type, detail, created_at
      FROM virtual_player_runtime_events ORDER BY id DESC LIMIT ?
    `).all(Math.max(1, Math.min(500, Math.floor(limit)))) as Array<Record<string, unknown>>;
  }
}
