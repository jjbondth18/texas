import { randomBytes, randomUUID } from "node:crypto";
import type Database from "better-sqlite3";
import type { StoreCatalogPackage } from "../store_catalog.js";
import type { SteamCommerceMode } from "../config.js";

export type SteamPurchaseStatus =
  | "created"
  | "initialized"
  | "authorized"
  | "cancelled"
  | "finalizing"
  | "finalized"
  | "granted"
  | "failed"
  | "refunded";

export interface SteamPurchaseOrderRecord {
  order_id: string;
  player_id: string;
  steam_id: string;
  package_id: string;
  package_title: string;
  chips_amount: number;
  gems_amount: number;
  price_minor: number;
  price_currency: string;
  environment: "sandbox" | "production";
  status: SteamPurchaseStatus;
  idempotency_key: string;
  steam_trans_id: string | null;
  created_at: string;
  initialized_at: string | null;
  authorized_at: string | null;
  finalized_at: string | null;
  granted_at: string | null;
  cancelled_at: string | null;
  failed_at: string | null;
  failure_code: string | null;
  failure_message: string | null;
}

export interface SteamPurchaseGrantResult {
  order: SteamPurchaseOrderRecord;
  wallet: { player_id: string; chips: number; gems: number; updated_at: string };
  already_granted: boolean;
}

export class SteamPurchaseRepository {
  constructor(private readonly db: Database.Database) {}

  createOrder(playerId: string, steamId: string, item: StoreCatalogPackage, mode: Exclude<SteamCommerceMode, "disabled">, idempotencyKey: string, now = new Date().toISOString()): SteamPurchaseOrderRecord {
    const existing = this.getByIdempotencyKey(playerId, idempotencyKey);
    if (existing) return existing;
    for (let attempt = 0; attempt < 5; attempt += 1) {
      const orderId = steamOrderId();
      try {
        this.db
          .prepare(
            `INSERT INTO steam_purchase_orders (
              order_id, player_id, steam_id, package_id, package_title, chips_amount, gems_amount,
              price_minor, price_currency, environment, status, idempotency_key, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'created', ?, ?)`,
          )
          .run(
            orderId,
            playerId,
            steamId,
            item.package_id,
            item.title,
            item.chips_amount,
            item.gems_amount,
            item.base_price_minor,
            item.base_currency,
            mode,
            idempotencyKey,
            now,
          );
        return this.get(orderId)!;
      } catch (error) {
        const raced = this.getByIdempotencyKey(playerId, idempotencyKey);
        if (raced) return raced;
        if (attempt === 4) throw error;
      }
    }
    throw new Error("steam_order_id_generation_failed");
  }

  get(orderId: string): SteamPurchaseOrderRecord | undefined {
    return this.db.prepare("SELECT * FROM steam_purchase_orders WHERE order_id = ?").get(orderId) as SteamPurchaseOrderRecord | undefined;
  }

  getForPlayer(orderId: string, playerId: string): SteamPurchaseOrderRecord | undefined {
    return this.db.prepare("SELECT * FROM steam_purchase_orders WHERE order_id = ? AND player_id = ?").get(orderId, playerId) as SteamPurchaseOrderRecord | undefined;
  }

  getByIdempotencyKey(playerId: string, idempotencyKey: string): SteamPurchaseOrderRecord | undefined {
    return this.db.prepare("SELECT * FROM steam_purchase_orders WHERE player_id = ? AND idempotency_key = ?").get(playerId, idempotencyKey) as SteamPurchaseOrderRecord | undefined;
  }

  recentForPlayer(playerId: string, limit = 20): SteamPurchaseOrderRecord[] {
    return this.db
      .prepare("SELECT * FROM steam_purchase_orders WHERE player_id = ? ORDER BY created_at DESC, order_id DESC LIMIT ?")
      .all(playerId, Math.min(50, Math.max(1, Math.floor(limit)))) as SteamPurchaseOrderRecord[];
  }

  markInitialized(orderId: string, steamTransId: string, now = new Date().toISOString()): SteamPurchaseOrderRecord {
    this.db
      .prepare("UPDATE steam_purchase_orders SET status = 'initialized', steam_trans_id = ?, initialized_at = ?, failure_code = NULL, failure_message = NULL WHERE order_id = ? AND status = 'created'")
      .run(steamTransId || null, now, orderId);
    return this.mustGet(orderId);
  }

  markAuthorized(orderId: string, now = new Date().toISOString()): SteamPurchaseOrderRecord {
    this.db.prepare("UPDATE steam_purchase_orders SET status = 'authorized', authorized_at = ? WHERE order_id = ? AND status = 'initialized'").run(now, orderId);
    return this.mustGet(orderId);
  }

  markCancelled(orderId: string, now = new Date().toISOString()): SteamPurchaseOrderRecord {
    this.db.prepare("UPDATE steam_purchase_orders SET status = 'cancelled', cancelled_at = ? WHERE order_id = ? AND status IN ('created', 'initialized', 'authorized')").run(now, orderId);
    return this.mustGet(orderId);
  }

  beginFinalizing(orderId: string): { order: SteamPurchaseOrderRecord; acquired: boolean } {
    const result = this.db.prepare("UPDATE steam_purchase_orders SET status = 'finalizing' WHERE order_id = ? AND status = 'authorized'").run(orderId);
    return { order: this.mustGet(orderId), acquired: result.changes === 1 };
  }

  markFinalized(orderId: string, steamTransId: string, now = new Date().toISOString()): SteamPurchaseOrderRecord {
    this.db
      .prepare("UPDATE steam_purchase_orders SET status = 'finalized', steam_trans_id = COALESCE(NULLIF(?, ''), steam_trans_id), finalized_at = ? WHERE order_id = ? AND status = 'finalizing'")
      .run(steamTransId, now, orderId);
    return this.mustGet(orderId);
  }

  markFailed(orderId: string, code: string, message: string, now = new Date().toISOString()): SteamPurchaseOrderRecord {
    this.db
      .prepare("UPDATE steam_purchase_orders SET status = 'failed', failed_at = ?, failure_code = ?, failure_message = ? WHERE order_id = ? AND status NOT IN ('granted', 'refunded')")
      .run(now, code, message.slice(0, 500), orderId);
    return this.mustGet(orderId);
  }

  grantFinalizedOrder(orderId: string, now = new Date().toISOString()): SteamPurchaseGrantResult {
    return this.db.transaction(() => {
      const order = this.mustGet(orderId);
      const wallet = this.db.prepare("SELECT player_id, chips, gems, updated_at FROM wallets WHERE player_id = ?").get(order.player_id) as
        | { player_id: string; chips: number; gems: number; updated_at: string }
        | undefined;
      if (!wallet) throw new Error("wallet_not_found");
      if (order.status === "granted") return { order, wallet, already_granted: true };
      if (order.status !== "finalized") throw new Error("steam_purchase_not_finalized");

      let chips = Number(wallet.chips);
      let gems = Number(wallet.gems);
      const displayLabel = `Steam Purchase - ${order.package_title}`;
      if (order.chips_amount > 0) {
        chips += order.chips_amount;
        this.db.prepare("UPDATE wallets SET chips = ?, updated_at = ? WHERE player_id = ?").run(chips, now, order.player_id);
        this.insertWalletTransaction(order, "chips", order.chips_amount, chips, "steam_purchase_chips", displayLabel, now);
      }
      if (order.gems_amount > 0) {
        gems += order.gems_amount;
        this.db.prepare("UPDATE wallets SET gems = ?, updated_at = ? WHERE player_id = ?").run(gems, now, order.player_id);
        this.insertWalletTransaction(order, "gems", order.gems_amount, gems, "steam_purchase_gems", displayLabel, now);
      }
      const result = this.db.prepare("UPDATE steam_purchase_orders SET status = 'granted', granted_at = ? WHERE order_id = ? AND status = 'finalized'").run(now, orderId);
      if (result.changes !== 1) throw new Error("steam_purchase_grant_race");
      return { order: this.mustGet(orderId), wallet: { player_id: order.player_id, chips, gems, updated_at: now }, already_granted: false };
    })();
  }

  recoverFinalizedOrders(): SteamPurchaseGrantResult[] {
    const rows = this.db.prepare("SELECT order_id FROM steam_purchase_orders WHERE status = 'finalized' ORDER BY finalized_at ASC").all() as Array<{ order_id: string }>;
    return rows.map((row) => this.grantFinalizedOrder(row.order_id));
  }

  private insertWalletTransaction(order: SteamPurchaseOrderRecord, currency: "chips" | "gems", amount: number, balanceAfter: number, reason: string, displayLabel: string, now: string): void {
    this.db
      .prepare(
        `INSERT INTO wallet_transactions (
          id, player_id, currency, amount, reason, balance_after, related_room_id, related_hand_id,
          reference_id, display_label, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, NULL, NULL, ?, ?, ?)`,
      )
      .run(randomUUID(), order.player_id, currency, amount, reason, balanceAfter, order.order_id, displayLabel, now);
  }

  private mustGet(orderId: string): SteamPurchaseOrderRecord {
    const order = this.get(orderId);
    if (!order) throw new Error("steam_purchase_not_found");
    return order;
  }
}

function steamOrderId(): string {
  const raw = BigInt(`0x${randomBytes(8).toString("hex")}`) & ((1n << 63n) - 1n);
  return (raw === 0n ? 1n : raw).toString(10);
}
