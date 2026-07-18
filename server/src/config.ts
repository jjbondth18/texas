import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

export type DatabaseDriver = "sqlite" | "postgres";
export type SteamAuthMode = "disabled" | "optional" | "required";
export type SteamCommerceMode = "disabled" | "sandbox" | "production";

export interface ServerConfig {
  nodeEnv: string;
  host: string;
  port: number;
  databaseDriver: DatabaseDriver;
  sqlitePath: string;
  databaseUrl: string;
  adminEnabled: boolean;
  adminLocalOnly: boolean;
  devShowPrivateCards: boolean;
  allowMockPurchases: boolean;
  mockPurchaseAllowedSteamIds: string[];
  legacyReplayImportAllowedSteamIds: string[];
  steamAuthMode: SteamAuthMode;
  steamAppId: string;
  steamWebApiPublisherKey: string;
  steamAuthIdentity: string;
  steamCommerceMode: SteamCommerceMode;
  steamPublisherWebApiKey: string;
}

loadDotEnv(resolve(process.cwd(), ".env"));

export const config: ServerConfig = {
  nodeEnv: process.env.NODE_ENV || "development",
  host: process.env.HOST || "127.0.0.1",
  port: integerEnv("PORT", 8080),
  databaseDriver: databaseDriverEnv(process.env.DATABASE_DRIVER),
  sqlitePath: process.env.SQLITE_PATH || process.env.TEXAS_DB_PATH || resolve(process.cwd(), "data/texas_dev.sqlite"),
  databaseUrl: process.env.DATABASE_URL || "",
  adminEnabled: booleanEnv("ADMIN_ENABLED", true),
  adminLocalOnly: booleanEnv("ADMIN_LOCAL_ONLY", true),
  devShowPrivateCards: (process.env.NODE_ENV || "development") === "production" ? false : booleanEnv("DEV_SHOW_PRIVATE_CARDS", false),
  allowMockPurchases: booleanEnv("ALLOW_MOCK_PURCHASES", (process.env.NODE_ENV || "development") !== "production"),
  mockPurchaseAllowedSteamIds: stringListEnv("MOCK_PURCHASE_ALLOWED_STEAM_IDS"),
  legacyReplayImportAllowedSteamIds: stringListEnv("LEGACY_REPLAY_IMPORT_ALLOWED_STEAM_IDS"),
  steamAuthMode: steamAuthModeEnv(process.env.STEAM_AUTH_MODE),
  steamAppId: process.env.STEAM_APP_ID || "",
  steamWebApiPublisherKey: process.env.STEAM_WEB_API_PUBLISHER_KEY || "",
  steamAuthIdentity: process.env.STEAM_AUTH_IDENTITY || "texas-server-v1",
  steamCommerceMode: steamCommerceModeEnv(process.env.STEAM_COMMERCE_MODE),
  steamPublisherWebApiKey: process.env.STEAM_PUBLISHER_WEB_API_KEY || process.env.STEAM_WEB_API_PUBLISHER_KEY || "",
};

export function configWarnings(value: ServerConfig = config): string[] {
  const warnings: string[] = [];
  if (value.nodeEnv === "production" && booleanEnv("DEV_SHOW_PRIVATE_CARDS", false)) {
    warnings.push("DEV_SHOW_PRIVATE_CARDS=true is ignored in production.");
  }
  if (value.nodeEnv === "production" && value.adminEnabled && !value.adminLocalOnly) {
    warnings.push("ADMIN_ENABLED=true with ADMIN_LOCAL_ONLY=false exposes unauthenticated debug pages unless protected by firewall/auth.");
  }
  if (value.steamAuthMode !== "disabled" && (value.steamAppId === "" || value.steamWebApiPublisherKey === "")) {
    warnings.push("STEAM_AUTH_MODE is enabled but STEAM_APP_ID or STEAM_WEB_API_PUBLISHER_KEY is not configured.");
  }
  if (value.steamCommerceMode !== "disabled" && (value.steamAppId === "" || value.steamPublisherWebApiKey === "")) {
    warnings.push("STEAM_COMMERCE_MODE is enabled but STEAM_APP_ID or STEAM_PUBLISHER_WEB_API_KEY is not configured; purchasing is unavailable.");
  }
  return warnings;
}

export function publicConfigSummary(value: ServerConfig = config): Record<string, string | number | boolean> {
  return {
    NODE_ENV: value.nodeEnv,
    HOST: value.host,
    PORT: value.port,
    DATABASE_DRIVER: value.databaseDriver,
    SQLITE_PATH: value.sqlitePath,
    ADMIN_ENABLED: value.adminEnabled,
    ADMIN_LOCAL_ONLY: value.adminLocalOnly,
    DEV_SHOW_PRIVATE_CARDS: value.devShowPrivateCards,
    ALLOW_MOCK_PURCHASES: value.allowMockPurchases,
    MOCK_PURCHASE_ALLOWED_STEAM_IDS_COUNT: value.mockPurchaseAllowedSteamIds.length,
    LEGACY_REPLAY_IMPORT_ALLOWED_STEAM_IDS_COUNT: value.legacyReplayImportAllowedSteamIds.length,
    STEAM_AUTH_MODE: value.steamAuthMode,
    STEAM_APP_ID: value.steamAppId,
    STEAM_AUTH_IDENTITY: value.steamAuthIdentity,
    STEAM_COMMERCE_MODE: value.steamCommerceMode,
    STEAM_COMMERCE_CONFIGURED: value.steamCommerceMode !== "disabled" && value.steamAppId !== "" && value.steamPublisherWebApiKey !== "",
  };
}

function integerEnv(name: string, fallback: number): number {
  const value = Number(process.env[name]);
  return Number.isInteger(value) && value > 0 ? value : fallback;
}

function booleanEnv(name: string, fallback: boolean): boolean {
  const value = process.env[name];
  if (value === undefined || value === "") return fallback;
  return ["1", "true", "yes", "on"].includes(value.toLowerCase());
}

function stringListEnv(name: string): string[] {
  const value = process.env[name];
  if (value === undefined || value.trim() === "") return [];
  return value
    .split(",")
    .map((entry) => entry.trim())
    .filter((entry) => entry !== "");
}

function databaseDriverEnv(value: string | undefined): DatabaseDriver {
  if (value === "postgres") return "postgres";
  return "sqlite";
}

function steamAuthModeEnv(value: string | undefined): SteamAuthMode {
  if (value === "optional" || value === "required") return value;
  return "disabled";
}

function steamCommerceModeEnv(value: string | undefined): SteamCommerceMode {
  if (value === "sandbox" || value === "production") return value;
  return "disabled";
}

function loadDotEnv(path: string): void {
  if (!existsSync(path)) return;
  const lines = readFileSync(path, "utf8").split(/\r?\n/);
  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (line === "" || line.startsWith("#")) continue;
    const separator = line.indexOf("=");
    if (separator <= 0) continue;
    const key = line.slice(0, separator).trim();
    const value = stripEnvQuotes(line.slice(separator + 1).trim());
    if (key !== "" && process.env[key] === undefined) process.env[key] = value;
  }
}

function stripEnvQuotes(value: string): string {
  if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
    return value.slice(1, -1);
  }
  return value;
}
