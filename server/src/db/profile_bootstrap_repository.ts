import type Database from "better-sqlite3";
import type { DailyBonusStatus } from "./login_bonus_repository.js";
import { LoginBonusRepository } from "./login_bonus_repository.js";

export interface PlayerProgressionRecord {
  player_id: string;
  total_xp: number;
  level: number;
  title_id: string;
  created_at: string;
  updated_at: string;
}

export interface PlayerStatisticsRecord {
  player_id: string;
  hands_played: number;
  hands_won: number;
  chips_won: number;
  gems_won: number;
  created_at: string;
  updated_at: string;
}

export interface ServerProfileSnapshot {
  player_id: string;
  display_name: string;
  avatar_id: string;
  wallet: { chips: number; gems: number };
  progression: { total_xp: number; level: number; title_id: string };
  statistics: { hands_played: number; hands_won: number; chips_won: number; gems_won: number };
  unlocked_avatar_ids: string[];
  daily_bonus: DailyBonusStatus;
  created_at: string;
  updated_at: string;
}

export class ProfileBootstrapRepository {
  constructor(
    private readonly db: Database.Database,
    private readonly loginBonus: LoginBonusRepository,
  ) {}

  ensureProgression(playerId: string, now = new Date().toISOString()): PlayerProgressionRecord {
    this.db
      .prepare(
        "INSERT OR IGNORE INTO player_progression (player_id, total_xp, level, title_id, created_at, updated_at) VALUES (?, 0, 1, 'new_player', ?, ?)",
      )
      .run(playerId, now, now);
    return this.db.prepare("SELECT * FROM player_progression WHERE player_id = ?").get(playerId) as PlayerProgressionRecord;
  }

  ensureStatistics(playerId: string, now = new Date().toISOString()): PlayerStatisticsRecord {
    this.db
      .prepare(
        "INSERT OR IGNORE INTO player_statistics (player_id, hands_played, hands_won, chips_won, gems_won, created_at, updated_at) VALUES (?, 0, 0, 0, 0, ?, ?)",
      )
      .run(playerId, now, now);
    return this.db.prepare("SELECT * FROM player_statistics WHERE player_id = ?").get(playerId) as PlayerStatisticsRecord;
  }

  bootstrapPlayer(playerId: string, now = new Date().toISOString()): void {
    this.db.transaction(() => {
      this.ensureProgression(playerId, now);
      this.ensureStatistics(playerId, now);
    })();
  }

  getProfileSnapshot(playerId: string): ServerProfileSnapshot {
    const player = this.db
      .prepare("SELECT player_id, display_name, avatar_id, created_at, updated_at FROM players WHERE player_id = ?")
      .get(playerId) as { player_id: string; display_name: string; avatar_id: string; created_at: string; updated_at: string } | undefined;
    const wallet = this.db.prepare("SELECT chips, gems FROM wallets WHERE player_id = ?").get(playerId) as { chips: number; gems: number } | undefined;
    const progression = this.db.prepare("SELECT * FROM player_progression WHERE player_id = ?").get(playerId) as PlayerProgressionRecord | undefined;
    const statistics = this.db.prepare("SELECT * FROM player_statistics WHERE player_id = ?").get(playerId) as PlayerStatisticsRecord | undefined;
    if (!player || !wallet || !progression || !statistics) throw new Error("player_profile_not_bootstrapped");
    const avatars = this.db
      .prepare("SELECT avatar_id FROM avatar_unlocks WHERE player_id = ? ORDER BY avatar_id")
      .all(playerId) as Array<{ avatar_id: string }>;
    return {
      player_id: player.player_id,
      display_name: player.display_name,
      avatar_id: player.avatar_id,
      wallet: { chips: Number(wallet.chips), gems: Number(wallet.gems) },
      progression: {
        total_xp: Number(progression.total_xp),
        level: Number(progression.level),
        title_id: progression.title_id,
      },
      statistics: {
        hands_played: Number(statistics.hands_played),
        hands_won: Number(statistics.hands_won),
        chips_won: Number(statistics.chips_won),
        gems_won: Number(statistics.gems_won),
      },
      unlocked_avatar_ids: avatars.map((row) => row.avatar_id),
      daily_bonus: this.loginBonus.status(playerId),
      created_at: player.created_at,
      updated_at: player.updated_at,
    };
  }
}
