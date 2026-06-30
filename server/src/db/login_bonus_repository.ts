import type Database from "better-sqlite3";
import { WalletRepository } from "./wallet_repository.js";

export interface DailyLoginResult {
  daily_login_awarded: boolean;
  awarded_chips: number;
}

const DAILY_LOGIN_CHIPS = 1000;

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
    if (existing) return { daily_login_awarded: false, awarded_chips: 0 };
    const claimedAt = now.toISOString();
    const transaction = this.db.transaction(() => {
      this.db
        .prepare("INSERT INTO daily_login_claims (player_id, claim_date, chips_awarded, claimed_at) VALUES (?, ?, ?, ?)")
        .run(playerId, claimDate, DAILY_LOGIN_CHIPS, claimedAt);
      this.walletRepository.addChips(playerId, DAILY_LOGIN_CHIPS, { reason: "daily_login_bonus", now: claimedAt });
    });
    transaction();
    return { daily_login_awarded: true, awarded_chips: DAILY_LOGIN_CHIPS };
  }
}
