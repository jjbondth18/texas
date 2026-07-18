import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { RoomManager as RoomManagerType } from "./room_manager.js";
import { storeCatalog } from "./store_catalog.js";
import type { SteamMicroTxnGateway, SteamMicroTxnResult } from "./services/steam_microtxn_gateway.js";
import type { SteamPurchaseOrderRecord } from "./db/steam_purchase_repository.js";

const testDirectory = mkdtempSync(join(tmpdir(), "texas-steam-commerce-"));
process.env.TEXAS_DB_PATH = join(testDirectory, "commerce.sqlite");
const { RoomManager } = await import("./room_manager.js");

class FakeWs {
  OPEN = 1;
  readyState = 1;
  sent: any[] = [];
  send(payload: string): void {
    this.sent.push(JSON.parse(payload));
  }
}

class FakeGateway implements SteamMicroTxnGateway {
  initCalls: SteamPurchaseOrderRecord[] = [];
  finalizeCalls: SteamPurchaseOrderRecord[] = [];
  initResult: SteamMicroTxnResult = { ok: true, steam_trans_id: "sandbox-init" };
  finalizeResult: SteamMicroTxnResult = { ok: true, steam_trans_id: "sandbox-final" };

  async initTxn(order: SteamPurchaseOrderRecord): Promise<SteamMicroTxnResult> {
    this.initCalls.push(order);
    return this.initResult;
  }

  async finalizeTxn(order: SteamPurchaseOrderRecord): Promise<SteamMicroTxnResult> {
    this.finalizeCalls.push(order);
    return this.finalizeResult;
  }

  async queryTxn(_order: SteamPurchaseOrderRecord): Promise<SteamMicroTxnResult> {
    return { ok: false, error_code: "not_implemented" };
  }
}

let identityCounter = 0;

async function settle(): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, 0));
  await new Promise((resolve) => setTimeout(resolve, 0));
}

function connectSteam(manager: RoomManagerType): { ws: FakeWs; playerId: string } {
  const ws = new FakeWs();
  const client = manager.connect(ws as any);
  identityCounter += 1;
  const steamId = String(76561199000000000n + BigInt(Date.now() % 1_000_000) + BigInt(identityCounter));
  manager.handle(client.id, {
    type: "hello",
    auth_provider: "steam",
    external_id: steamId,
    player_name: `Commerce ${identityCounter}`,
  });
  const hello = ws.sent.find((message) => message.type === "hello");
  return { ws, playerId: String(hello.player_id) };
}

function latest(ws: FakeWs, type: string): any {
  return ws.sent.filter((message) => message.type === type).at(-1);
}

const catalog = storeCatalog();
assert.deepEqual(catalog.map((item) => item.package_id), ["starter_pack", "club_pack", "pro_pack", "high_roller_pack"]);
assert(catalog.every((item) => item.category === "bundle" && item.chips_amount > 0 && item.gems_amount > 0));
assert.deepEqual(catalog.map((item) => [item.chips_amount, item.gems_amount, item.base_price_minor]), [
  [20_000, 100, 199],
  [60_000, 400, 499],
  [150_000, 1_000, 999],
  [350_000, 2_500, 1_999],
]);

const gateway = new FakeGateway();
const manager = new RoomManager({ steamCommerceGateway: gateway, steamCommerceMode: "sandbox", steamCommerceConfigured: true });
const first = connectSteam(manager);
const wallets = (manager as any).wallets;
const before = wallets.get(first.playerId);

manager.handle(first.playerId, { type: "get_store_catalog" });
const catalogMessage = latest(first.ws, "store_catalog");
assert.equal(catalogMessage.commerce_available, true);
assert.deepEqual(catalogMessage.store_catalog.map((item: any) => item.package_id), catalog.map((item) => item.package_id));

manager.handle(first.playerId, {
  type: "create_store_purchase",
  package_id: "club_pack",
  idempotency_key: "club-one",
  chips_amount: 999_999_999,
  gems_amount: 999_999,
  price_minor: 1,
} as any);
await settle();
const created = latest(first.ws, "store_purchase_created");
assert.equal(created.order.package_id, "club_pack");
assert.equal(created.order.chips_amount, 60_000, "client must not alter chips grant");
assert.equal(created.order.gems_amount, 400, "client must not alter gems grant");
assert.equal(created.order.price_minor, 499, "client must not alter catalog price");
assert.equal(gateway.initCalls.length, 1);
assert.equal(gateway.initCalls[0].price_minor, 499, "InitTxn must use the server catalog snapshot");

manager.handle(first.playerId, { type: "create_store_purchase", package_id: "club_pack", idempotency_key: "club-one" });
await settle();
assert.equal(gateway.initCalls.length, 1, "idempotent create must not repeat InitTxn");

manager.handle(first.playerId, { type: "store_purchase_authorization", order_id: created.order.order_id, authorized: true });
await settle();
const granted = latest(first.ws, "store_purchase_result");
assert.equal(granted.order.status, "granted");
assert.equal(wallets.get(first.playerId).chips, before.chips + 60_000);
assert.equal(wallets.get(first.playerId).gems, before.gems + 400);
assert.equal(gateway.finalizeCalls.length, 1);
const purchaseTransactions = wallets.transactionsForPlayer(first.playerId, 20).filter((item: any) => item.reference_id === created.order.order_id);
assert.deepEqual(purchaseTransactions.map((item: any) => item.reason).sort(), ["steam_purchase_chips", "steam_purchase_gems"]);
assert(purchaseTransactions.every((item: any) => item.display_label === "Steam Purchase - Club Pack"));

manager.handle(first.playerId, { type: "store_purchase_authorization", order_id: created.order.order_id, authorized: true });
await settle();
assert.equal(gateway.finalizeCalls.length, 1, "duplicate callback must not repeat FinalizeTxn");
assert.equal(wallets.get(first.playerId).chips, before.chips + 60_000, "duplicate callback must not grant twice");
assert.equal(wallets.get(first.playerId).gems, before.gems + 400, "duplicate callback must not grant twice");

manager.handle(first.playerId, { type: "create_store_purchase", package_id: "starter_pack", idempotency_key: "cancel-one" });
await settle();
const cancelledOrder = latest(first.ws, "store_purchase_created").order;
const beforeCancel = wallets.get(first.playerId);
manager.handle(first.playerId, { type: "store_purchase_authorization", order_id: cancelledOrder.order_id, authorized: false });
await settle();
assert.equal(latest(first.ws, "store_purchase_result").order.status, "cancelled");
assert.deepEqual(wallets.get(first.playerId), beforeCancel, "cancelled purchase must not grant currency");

gateway.finalizeResult = { ok: false, error_code: "sandbox_finalize_failed" };
manager.handle(first.playerId, { type: "create_store_purchase", package_id: "pro_pack", idempotency_key: "fail-one" });
await settle();
const failedOrder = latest(first.ws, "store_purchase_created").order;
const beforeFailure = wallets.get(first.playerId);
manager.handle(first.playerId, { type: "store_purchase_authorization", order_id: failedOrder.order_id, authorized: true });
await settle();
assert.equal(latest(first.ws, "store_purchase_result").order.status, "failed");
assert.deepEqual(wallets.get(first.playerId), beforeFailure, "FinalizeTxn failure must not grant currency");

manager.handle(first.playerId, { type: "create_store_purchase", package_id: "chip_starter", idempotency_key: "old-product" });
await settle();
assert.equal(latest(first.ws, "error").error_code, "store_package_not_found");

const second = connectSteam(manager);
assert.throws(
  () => manager.handle(second.playerId, { type: "get_store_purchase_status", order_id: created.order.order_id }),
  /steam_purchase_not_found/,
  "players must not query another player's order",
);

const purchaseRepository = (manager as any).steamPurchases;
const recoveryItem = catalog.find((item) => item.package_id === "high_roller_pack")!;
let recoveryOrder = purchaseRepository.createOrder(first.playerId, "76561199000000001", recoveryItem, "sandbox", "restart-recovery");
recoveryOrder = purchaseRepository.markInitialized(recoveryOrder.order_id, "recovery-init");
recoveryOrder = purchaseRepository.markAuthorized(recoveryOrder.order_id);
purchaseRepository.beginFinalizing(recoveryOrder.order_id);
recoveryOrder = purchaseRepository.markFinalized(recoveryOrder.order_id, "recovery-final");
const beforeRecovery = wallets.get(first.playerId);
new RoomManager({ steamCommerceGateway: new FakeGateway(), steamCommerceMode: "sandbox", steamCommerceConfigured: true });
assert.equal(wallets.get(first.playerId).chips, beforeRecovery.chips + 350_000, "restart recovery should grant finalized Chips once");
assert.equal(wallets.get(first.playerId).gems, beforeRecovery.gems + 2_500, "restart recovery should grant finalized Gems once");
new RoomManager({ steamCommerceGateway: new FakeGateway(), steamCommerceMode: "sandbox", steamCommerceConfigured: true });
assert.equal(wallets.get(first.playerId).chips, beforeRecovery.chips + 350_000, "repeated restart recovery must not double grant");
assert.equal(wallets.get(first.playerId).gems, beforeRecovery.gems + 2_500, "repeated restart recovery must not double grant");

const disabledManager = new RoomManager({ steamCommerceGateway: new FakeGateway(), steamCommerceMode: "disabled", steamCommerceConfigured: false });
const disabled = connectSteam(disabledManager);
disabledManager.handle(disabled.playerId, { type: "get_store_catalog" });
assert.equal(latest(disabled.ws, "store_catalog").commerce_available, false, "production-safe default must keep commerce disabled");
const { publicConfigSummary } = await import("./config.js");
assert(!Object.keys(publicConfigSummary()).some((key) => key.toLowerCase().includes("key")), "public config must not expose the publisher key");

console.log("Steam commerce tests passed.");
const { closeDatabase } = await import("./db/database.js");
closeDatabase();
rmSync(testDirectory, { recursive: true, force: true });
