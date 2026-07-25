type VirtualProxyRoute = "state" | "enabled" | "config" | "profile" | "offline";

export interface VirtualProxyResponse {
  status: number;
  body: unknown;
}

export class VirtualProxyUnavailableError extends Error {
  readonly statusCode = 502;
}

const ROUTES: Record<VirtualProxyRoute, { method: "GET" | "POST"; pathname: string }> = {
  state: { method: "GET", pathname: "/admin/virtual" },
  enabled: { method: "POST", pathname: "/admin/virtual/enabled" },
  config: { method: "POST", pathname: "/admin/virtual/config" },
  profile: { method: "POST", pathname: "/admin/virtual/profile" },
  offline: { method: "POST", pathname: "/admin/virtual/offline" },
};

export async function proxyVirtualRequest(
  route: VirtualProxyRoute,
  body: Record<string, unknown> = {},
  options: { baseUrl?: string; timeoutMs?: number; fetchImpl?: typeof fetch } = {},
): Promise<VirtualProxyResponse> {
  const target = ROUTES[route];
  const base = safeGameServerAdminUrl(options.baseUrl ?? process.env.GAME_SERVER_ADMIN_URL ?? "http://127.0.0.1:8080");
  const url = new URL(target.pathname, base);
  if (route === "enabled") {
    if (typeof body.enabled !== "boolean") throw new Error("enabled 必须是布尔值");
    url.searchParams.set("value", String(body.enabled));
  } else if (route === "config") {
    const config = validateEditableVirtualConfig(body);
    for (const [key, value] of Object.entries(config)) url.searchParams.set(key, String(value));
  } else if (route === "profile") {
    const playerId = virtualPlayerId(body.player_id);
    if (typeof body.enabled !== "boolean") throw new Error("enabled 必须是布尔值");
    url.searchParams.set("player_id", playerId);
    url.searchParams.set("enabled", String(body.enabled));
  } else if (route === "offline") {
    if (body.player_id !== undefined && body.player_id !== "") {
      url.searchParams.set("player_id", virtualPlayerId(body.player_id));
    }
  }

  const fetchImpl = options.fetchImpl ?? fetch;
  let response: Response;
  try {
    response = await fetchImpl(url, {
      method: target.method,
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(options.timeoutMs ?? 4_000),
    });
  } catch {
    throw new VirtualProxyUnavailableError("游戏服务不可达，请确认 texas-server 正在本机 127.0.0.1 运行");
  }
  const text = await response.text();
  let value: unknown = {};
  try {
    value = text === "" ? {} : JSON.parse(text);
  } catch {
    value = { error: text.slice(0, 500) || `游戏服务返回 HTTP ${response.status}` };
  }
  if (!response.ok) {
    const message = typeof value === "object" && value && "error" in value
      ? String((value as { error: unknown }).error)
      : `游戏服务返回 HTTP ${response.status}`;
    return { status: response.status >= 400 && response.status < 500 ? response.status : 502, body: { error: `Virtual 操作失败：${message}` } };
  }
  return { status: response.status, body: value };
}

export function validateEditableVirtualConfig(body: Record<string, unknown>): Record<string, number> {
  const keys = [
    "target_online",
    "maximum_online",
    "maximum_per_room",
    "join_delay_min_ms",
    "join_delay_max_ms",
    "session_hand_min",
    "session_hand_max",
  ] as const;
  const values = Object.fromEntries(keys.map((key) => [key, strictNonNegativeInteger(body[key], key)])) as Record<(typeof keys)[number], number>;
  if (values.maximum_per_room < 1) throw new Error("maximum_per_room 必须至少为 1");
  if (values.target_online > values.maximum_online) throw new Error("target_online 不能大于 maximum_online");
  if (values.join_delay_min_ms > values.join_delay_max_ms) throw new Error("join_delay_min_ms 不能大于 join_delay_max_ms");
  if (values.session_hand_min > values.session_hand_max) throw new Error("session_hand_min 不能大于 session_hand_max");
  return values;
}

function strictNonNegativeInteger(value: unknown, name: string): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < 0) throw new Error(`${name} 必须是非负整数`);
  return value;
}

function virtualPlayerId(value: unknown): string {
  const playerId = String(value ?? "");
  if (!/^virtual:vp_[A-Za-z0-9_-]+$/.test(playerId)) throw new Error("Virtual Player ID 无效");
  return playerId;
}

function safeGameServerAdminUrl(value: string): URL {
  const url = new URL(value);
  if (url.protocol !== "http:" || !["127.0.0.1", "::1", "localhost"].includes(url.hostname)) {
    throw new Error("GAME_SERVER_ADMIN_URL 必须使用本机 HTTP 地址");
  }
  if (url.username || url.password || url.search || url.hash || !["", "/"].includes(url.pathname)) {
    throw new Error("GAME_SERVER_ADMIN_URL 格式无效");
  }
  return url;
}
