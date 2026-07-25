import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { proxyVirtualRequest, validateEditableVirtualConfig } from "./virtual_proxy.js";

const validConfig = {
  target_online: 2,
  maximum_online: 4,
  maximum_per_room: 1,
  join_delay_min_ms: 1000,
  join_delay_max_ms: 2000,
  session_hand_min: 3,
  session_hand_max: 8,
};

assert.deepEqual(validateEditableVirtualConfig(validConfig), validConfig);
assert.throws(() => validateEditableVirtualConfig({ ...validConfig, target_online: 5 }), /target_online/);
assert.throws(() => validateEditableVirtualConfig({ ...validConfig, join_delay_min_ms: 3000 }), /join_delay_min_ms/);
assert.throws(() => validateEditableVirtualConfig({ ...validConfig, session_hand_min: 9 }), /session_hand_min/);
assert.throws(() => validateEditableVirtualConfig({ ...validConfig, maximum_per_room: 0 }), /maximum_per_room/);
assert.throws(() => validateEditableVirtualConfig({ ...validConfig, maximum_online: 4.5 }), /maximum_online/);
assert.throws(() => validateEditableVirtualConfig({ ...validConfig, maximum_online: "" }), /maximum_online/);

const calls: Array<{ url: string; method: string }> = [];
const fakeFetch = async (input: string | URL | Request, init?: RequestInit): Promise<Response> => {
  calls.push({ url: String(input), method: String(init?.method) });
  return new Response(JSON.stringify({ ok: true }), { status: 200, headers: { "content-type": "application/json" } });
};
await proxyVirtualRequest("state", {}, { fetchImpl: fakeFetch, baseUrl: "http://127.0.0.1:8080" });
await proxyVirtualRequest("config", validConfig, { fetchImpl: fakeFetch, baseUrl: "http://127.0.0.1:8080" });
await proxyVirtualRequest("profile", { player_id: "virtual:vp_001", enabled: false }, { fetchImpl: fakeFetch });
await proxyVirtualRequest("offline", {}, { fetchImpl: fakeFetch });
assert.equal(new URL(calls[0].url).pathname, "/admin/virtual");
assert.equal(calls[0].method, "GET");
assert.equal(new URL(calls[1].url).pathname, "/admin/virtual/config");
assert.equal(new URL(calls[1].url).searchParams.get("target_online"), "2");
assert.equal(calls[1].method, "POST");
assert.equal(new URL(calls[2].url).searchParams.get("player_id"), "virtual:vp_001");
assert.equal(new URL(calls[3].url).searchParams.has("player_id"), false);
await assert.rejects(proxyVirtualRequest("offline", { player_id: "https://attacker.invalid/" }, { fetchImpl: fakeFetch }), /Player ID/);
await assert.rejects(proxyVirtualRequest("state", {}, { fetchImpl: fakeFetch, baseUrl: "https://example.com" }), /本机/);

await assert.rejects(
  proxyVirtualRequest("state", {}, { fetchImpl: async () => { throw new Error("offline"); } }),
  /游戏服务不可达/,
);

const appJs = readFileSync(resolve(process.cwd(), "../tools/admin/web/app.js"), "utf8");
const appCss = readFileSync(resolve(process.cwd(), "../tools/admin/web/app.css"), "utf8");
assert.match(appJs, /\["virtual", "Virtual Players"\]/);
assert.match(appJs, /\/api\/virtual/);
assert.match(appJs, /session_hand_target/);
assert.match(appJs, /Profile Enabled/);
assert.match(appJs, /Runtime State/);
assert.match(appJs, /Safe Offline All/);
assert.match(appJs, /confirm\(/);
assert.doesNotMatch(appJs, /style="/);
assert.match(appCss, /\[hidden\]\{display:none!important\}/);

console.log("admin virtual proxy/ui smoke: ok");
