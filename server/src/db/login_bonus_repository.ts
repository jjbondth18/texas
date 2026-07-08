import type Database from "better-sqlite3";
import { WalletRepository } from "./wallet_repository.js";

export interface DailyLoginResult {
  daily_login_awarded: boolean;
  awarded_chips: number;
  awarded_xp: number;
  awarded_gems: number;
  reward_day: number;
}

const DAILY_BONUS_REWARDS = [
  { day: 1, chips: 500, xp: 25, gems: 0 },
  { day: 2, chips: 750, xp: 25, gems: 0 },
  { day: 3, chips: 1000, xp: 25, gems: 0 },
  { day: 4, chips: 1250, xp: 25, gems: 0 },
  { day: 5, chips: 1500, xp: 25, gems: 0 },
  { day: 6, chips: 2000, xp: 25, gems: 0 },
  { day: 7, chips: 5000, xp: 50, gems: 5 },
] as const;

export class LoginBonusRepository {
  constructor(
    private readonly db: Database.Database,
    private readonly walletRepository: WalletRepository,
  ) {}

  claimTodayIfNeeded(playerId: string, now = new Date()): DailyLoginResult {
    const claimDate = now.toISOString().slice(0, 10);
    const existing = this.db
      .prepare("SELECT 1 AS found FROM daily_login_claims WHERE player_id = ? AND claim_date = ?")
      .get(playerId, claimDate);
    if (existing) return { daily_login_awarded: false, awarded_chips: 0, awarded_xp: 0, awarded_gems: 0, reward_day: 0 };
    const previousClaimRow = this.db
      .prepare("SELECT COUNT(*) AS count FROM daily_login_claims WHERE player_id = ?")
      .get(playerId) as { count?: number } | undefined;
    const previousClaimCount = Number(previousClaimRow?.count ?? 0);
    const reward = DAILY_BONUS_REWARDS[previousClaimCount % DAILY_BONUS_REWARDS.length];
    const claimedAt = now.toISOString();
    const transaction = this.db.transaction(() => {
      this.db
        .prepare("INSERT INTO daily_login_claims (player_id, claim_date, chips_awarded, claimed_at) VALUES (?, ?, ?, ?)")
        .run(playerId, claimDate, reward.chips, claimedAt);
      this.walletRepository.addChips(playerId, reward.chips, { reason: "daily_login_bonus_chips", now: claimedAt });
      if (reward.gems > 0) this.walletRepository.addGems(playerId, reward.gems, { reason: "daily_login_bonus_gems", now: claimedAt });
    });
    transaction();
    return {
      daily_login_awarded: true,
      awarded_chips: reward.chips,
      awarded_xp: reward.xp,
      awarded_gems: reward.gems,
      reward_day: reward.day,
    };
  }
}
