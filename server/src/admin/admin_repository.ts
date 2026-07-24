import { randomUUID } from "node:crypto";
import type Database from "better-sqlite3";

type Currency = "chips" | "gems";

export class AdminRepository {
  constructor(private readonly db: Database.Database) {}

  dashboard(): Record<string, unknown> {
    const scalar = (sql: string) => Number((this.db.prepare(sql).get() as { n: number }).n);
    return {
      database: "connected",
      players: scalar("SELECT COUNT(*) n FROM players"),
      active_24h: scalar("SELECT COUNT(*) n FROM players WHERE last_login_at >= datetime('now', '-24 hours')"),
      chips: scalar("SELECT COALESCE(SUM(chips), 0) n FROM wallets"),
      gems: scalar("SELECT COALESCE(SUM(gems), 0) n FROM wallets"),
      matches: scalar("SELECT COUNT(DISTINCT COALESCE(hand_id, id)) n FROM table_session_results"),
      recent_matches: scalar("SELECT COUNT(DISTINCT COALESCE(hand_id, id)) n FROM table_session_results WHERE created_at >= datetime('now', '-24 hours')"),
      replays: scalar("SELECT COUNT(*) n FROM replay_index"),
      unlocks: scalar("SELECT COUNT(*) n FROM replay_unlocks"),
      audits: this.db.prepare("SELECT * FROM admin_audit_logs ORDER BY created_at DESC LIMIT 10").all(),
    };
  }

  players(query = "", page = 1): unknown[] {
    const q = `%${query.trim()}%`;
    return this.db.prepare(`
      SELECT p.player_id, i.external_id steam_id, p.display_name, p.steam_persona_name,
             w.chips, w.gems, COALESCE(pg.total_xp, 0) total_xp, p.created_at,
             p.last_login_at, COALESCE(s.is_banned, 0) is_banned
      FROM players p
      LEFT JOIN wallets w ON w.player_id=p.player_id
      LEFT JOIN player_progression pg ON pg.player_id=p.player_id
      LEFT JOIN player_identities i ON i.player_id=p.player_id AND i.provider='steam'
      LEFT JOIN player_admin_state s ON s.player_id=p.player_id
      WHERE ?='' OR p.player_id LIKE ? OR COALESCE(i.external_id,'') LIKE ? OR p.display_name LIKE ? OR COALESCE(p.steam_persona_name,'') LIKE ?
      ORDER BY COALESCE(p.last_login_at,p.created_at) DESC LIMIT 100 OFFSET ?
    `).all(query.trim(), q, q, q, q, offset(page));
  }

  player(playerId: string): Record<string, unknown> | undefined {
    const base = this.db.prepare(`
      SELECT p.*, i.external_id steam_id, w.chips, w.gems, COALESCE(pg.total_xp,0) total_xp,
        COALESCE(pg.level,1) level, pg.title_id, COALESCE(s.is_banned,0) is_banned,
        s.ban_reason, s.banned_at, COALESCE(s.admin_note,'') admin_note
      FROM players p LEFT JOIN wallets w ON w.player_id=p.player_id
      LEFT JOIN player_progression pg ON pg.player_id=p.player_id
      LEFT JOIN player_identities i ON i.player_id=p.player_id AND i.provider='steam'
      LEFT JOIN player_admin_state s ON s.player_id=p.player_id WHERE p.player_id=?
    `).get(playerId) as Record<string, unknown> | undefined;
    if (!base) return undefined;
    return {
      ...base,
      daily_bonus: this.db.prepare("SELECT * FROM daily_login_claims WHERE player_id=? ORDER BY claimed_at DESC LIMIT 14").all(playerId),
      transactions: this.db.prepare("SELECT * FROM wallet_transactions WHERE player_id=? ORDER BY created_at DESC LIMIT 30").all(playerId),
      matches: this.db.prepare("SELECT * FROM table_session_results WHERE player_id=? ORDER BY created_at DESC LIMIT 30").all(playerId),
      replays: this.db.prepare("SELECT r.* FROM replay_index r JOIN replay_participants p ON p.replay_id=r.replay_id WHERE p.player_id=? ORDER BY r.created_at DESC LIMIT 30").all(playerId),
      unlocks: this.db.prepare("SELECT * FROM replay_unlocks WHERE player_id=? ORDER BY unlocked_at DESC LIMIT 30").all(playerId),
      audits: this.db.prepare("SELECT * FROM admin_audit_logs WHERE player_id=? ORDER BY created_at DESC LIMIT 30").all(playerId),
    };
  }

  adjustWallet(playerId: string, currency: Currency, amount: number, reason: string): unknown {
    if (!Number.isSafeInteger(amount) || amount === 0) throw new Error("变动数量必须是非零整数");
    const column = currency === "chips" ? "chips" : "gems";
    return this.db.transaction(() => {
      const before = this.db.prepare(`SELECT ${column} value FROM wallets WHERE player_id=?`).get(playerId) as { value: number } | undefined;
      if (!before) throw new Error("玩家钱包不存在");
      const after = before.value + amount;
      if (after < 0) throw new Error("余额不足，操作已拒绝");
      const now = new Date().toISOString();
      const auditId = randomUUID();
      this.db.prepare(`UPDATE wallets SET ${column}=?, updated_at=? WHERE player_id=? AND ${column}=?`).run(after, now, playerId, before.value);
      const changed = this.db.prepare("SELECT changes() n").get() as { n: number };
      if (changed.n !== 1) throw new Error("余额发生并发变化，请刷新后重试");
      this.db.prepare("INSERT INTO wallet_transactions(id,player_id,currency,amount,reason,balance_after,created_at) VALUES(?,?,?,?,?,?,?)")
        .run(randomUUID(), playerId, currency, amount, `admin:${reason}`, after, now);
      this.audit(auditId, playerId, `adjust_${currency}`, currency, before.value, amount, after, reason, now);
      return { before: before.value, amount, after, audit_id: auditId };
    })();
  }

  setXp(playerId: string, value: number, reason: string): unknown {
    if (!Number.isSafeInteger(value) || value < 0) throw new Error("XP 必须是非负整数");
    return this.db.transaction(() => {
      const row = this.db.prepare("SELECT total_xp FROM player_progression WHERE player_id=?").get(playerId) as { total_xp: number } | undefined;
      if (!row) throw new Error("玩家进度不存在");
      const now = new Date().toISOString();
      this.db.prepare("UPDATE player_progression SET total_xp=?,level=?,updated_at=? WHERE player_id=?")
        .run(value, Math.floor(value / 100) + 1, now, playerId);
      this.audit(randomUUID(), playerId, "set_xp", "xp", row.total_xp, value-row.total_xp, value, reason, now);
      return { before: row.total_xp, after: value };
    })();
  }

  resetDaily(playerId: string, reason: string): unknown {
    return this.db.transaction(() => {
      const rows = this.db.prepare("DELETE FROM daily_login_claims WHERE player_id=?").run(playerId).changes;
      this.audit(randomUUID(), playerId, "reset_daily_bonus", null, rows, -rows, 0, reason, new Date().toISOString());
      return { deleted_claims: rows };
    })();
  }

  moderate(playerId: string, banned: boolean, reason: string): unknown {
    return this.db.transaction(() => {
      const now = new Date().toISOString();
      const before = Number((this.db.prepare("SELECT COALESCE(is_banned,0) value FROM player_admin_state WHERE player_id=?").get(playerId) as { value?: number } | undefined)?.value ?? 0);
      this.db.prepare(`INSERT INTO player_admin_state(player_id,is_banned,ban_reason,banned_at,updated_at) VALUES(?,?,?,?,?)
        ON CONFLICT(player_id) DO UPDATE SET is_banned=excluded.is_banned,ban_reason=excluded.ban_reason,banned_at=excluded.banned_at,updated_at=excluded.updated_at`)
        .run(playerId, banned ? 1 : 0, banned ? reason : null, banned ? now : null, now);
      this.audit(randomUUID(), playerId, banned ? "ban_player" : "unban_player", null, before, (banned?1:0)-before, banned?1:0, reason, now);
      return { is_banned: banned };
    })();
  }

  note(playerId: string, note: string): unknown {
    return this.db.transaction(() => {
      const now = new Date().toISOString();
      this.db.prepare(`INSERT INTO player_admin_state(player_id,admin_note,updated_at) VALUES(?,?,?)
        ON CONFLICT(player_id) DO UPDATE SET admin_note=excluded.admin_note,updated_at=excluded.updated_at`).run(playerId, note, now);
      this.audit(randomUUID(), playerId, "update_note", null, null, null, null, "admin note updated", now);
      return { saved: true };
    })();
  }

  transactions(page = 1): unknown[] { return this.db.prepare("SELECT * FROM wallet_transactions ORDER BY created_at DESC LIMIT 100 OFFSET ?").all(offset(page)); }
  audits(page = 1): unknown[] { return this.db.prepare("SELECT * FROM admin_audit_logs ORDER BY created_at DESC LIMIT 100 OFFSET ?").all(offset(page)); }
  matches(page = 1): unknown[] {
    return this.db.prepare(`SELECT COALESCE(hand_id,id) hand_id, room_id, MIN(created_at) started_at, MAX(created_at) ended_at,
      GROUP_CONCAT(player_id) players, SUM(CASE WHEN chip_delta<0 THEN -chip_delta ELSE 0 END) buy_in,
      SUM(chip_delta) net_result, 1 completed,
      EXISTS(SELECT 1 FROM replay_index r WHERE r.hand_id=table_session_results.hand_id) has_replay
      FROM table_session_results GROUP BY COALESCE(hand_id,id),room_id ORDER BY ended_at DESC LIMIT 100 OFFSET ?`).all(offset(page));
  }
  replays(page = 1): unknown[] {
    return this.db.prepare(`SELECT r.replay_id,r.hand_id,r.room_id,r.created_at,r.integrity_status,r.algorithm,
      GROUP_CONCAT(p.player_id) players, EXISTS(SELECT 1 FROM replay_keys k WHERE k.replay_id=r.replay_id) has_key,
      (SELECT COUNT(*) FROM replay_unlocks u WHERE u.replay_id=r.replay_id) unlock_count,
      (SELECT COALESCE(SUM(cost),0) FROM replay_unlocks u WHERE u.replay_id=r.replay_id) unlock_cost
      FROM replay_index r LEFT JOIN replay_participants p ON p.replay_id=r.replay_id
      GROUP BY r.replay_id ORDER BY r.created_at DESC LIMIT 100 OFFSET ?`).all(offset(page));
  }

  private audit(id:string, playerId:string|null, action:string, currency:string|null, before:number|null, amount:number|null, after:number|null, reason:string, now:string): void {
    this.db.prepare("INSERT INTO admin_audit_logs(id,player_id,action_type,currency,value_before,change_amount,value_after,reason,created_at) VALUES(?,?,?,?,?,?,?,?,?)")
      .run(id, playerId, action, currency, before, amount, after, reason, now);
  }
}

function offset(page: number): number {
  const safePage = Number.isInteger(page) && page > 0 ? Math.min(page, 10000) : 1;
  return (safePage - 1) * 100;
}
