import type { SteamCommerceMode } from "../config.js";
import type { SteamPurchaseOrderRecord } from "../db/steam_purchase_repository.js";

export interface SteamMicroTxnResult {
  ok: boolean;
  steam_trans_id?: string;
  error_code?: string;
  error_message?: string;
  raw_status?: string;
}

export interface SteamMicroTxnGateway {
  initTxn(order: SteamPurchaseOrderRecord): Promise<SteamMicroTxnResult>;
  finalizeTxn(order: SteamPurchaseOrderRecord): Promise<SteamMicroTxnResult>;
  queryTxn(order: SteamPurchaseOrderRecord): Promise<SteamMicroTxnResult>;
}

export class SteamWebApiMicroTxnGateway implements SteamMicroTxnGateway {
  constructor(
    private readonly mode: SteamCommerceMode,
    private readonly publisherKey: string,
    private readonly appId: string,
  ) {}

  async initTxn(order: SteamPurchaseOrderRecord): Promise<SteamMicroTxnResult> {
    const params = new URLSearchParams({
      key: this.publisherKey,
      appid: this.appId,
      orderid: order.order_id,
      steamid: order.steam_id,
      itemcount: "1",
      language: "en",
      currency: order.price_currency,
      usersession: "client",
      "itemid[0]": order.package_id,
      "qty[0]": "1",
      "amount[0]": String(order.price_minor),
      "description[0]": order.package_title,
      format: "json",
    });
    return this.post("InitTxn", "v3", params);
  }

  async finalizeTxn(order: SteamPurchaseOrderRecord): Promise<SteamMicroTxnResult> {
    return this.post("FinalizeTxn", "v2", new URLSearchParams({ key: this.publisherKey, appid: this.appId, orderid: order.order_id, format: "json" }));
  }

  async queryTxn(order: SteamPurchaseOrderRecord): Promise<SteamMicroTxnResult> {
    // Boundary reserved for restart reconciliation and a future scheduled GetReport worker.
    return this.post("QueryTxn", "v3", new URLSearchParams({ key: this.publisherKey, appid: this.appId, orderid: order.order_id, format: "json" }));
  }

  private async post(method: string, version: string, params: URLSearchParams): Promise<SteamMicroTxnResult> {
    if (this.mode === "disabled" || this.publisherKey === "" || this.appId === "") return { ok: false, error_code: "steam_commerce_unavailable" };
    const interfaceName = this.mode === "sandbox" ? "ISteamMicroTxnSandbox" : "ISteamMicroTxn";
    try {
      const response = await fetch(`https://partner.steam-api.com/${interfaceName}/${method}/${version}/`, {
        method: "POST",
        headers: { "content-type": "application/x-www-form-urlencoded" },
        body: params,
      });
      const payload = (await response.json()) as Record<string, unknown>;
      const responseBody = asRecord(payload.response);
      const paramsBody = asRecord(responseBody.params);
      const errorBody = asRecord(responseBody.error);
      const result = String(responseBody.result || "");
      if (!response.ok || result !== "OK") {
        return {
          ok: false,
          error_code: String(errorBody.errorcode || `steam_${method.toLowerCase()}_failed`),
          error_message: String(errorBody.errordesc || `Steam ${method} failed.`),
        };
      }
      return {
        ok: true,
        steam_trans_id: String(paramsBody.transid || ""),
        raw_status: String(paramsBody.status || result),
      };
    } catch {
      return { ok: false, error_code: "steam_commerce_network_error", error_message: `Steam ${method} request failed.` };
    }
  }
}

function asRecord(value: unknown): Record<string, unknown> {
  return typeof value === "object" && value !== null ? (value as Record<string, unknown>) : {};
}
