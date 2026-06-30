import { resolve } from "node:path";

export type DatabaseDriver = "sqlite" | "postgres";

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
}

export const config: ServerConfig = {
  nodeEnv: process.env.NODE_ENV || "development",
  host: process.env.HOST || "127.0.0.1",
  port: integerEnv("PORT", 8080),
  databaseDriver: databaseDriverEnv(process.env.DATABASE_DRIVER),
  sqlitePath: process.env.SQLITE_PATH || process.env.TEXAS_DB_PATH || resolve(process.cwd(), "data/texas_dev.sqlite"),
  databaseUrl: process.env.DATABASE_URL || "",
  adminEnabled: booleanEnv("ADMIN_ENABLED", true),
  adminLocalOnly: booleanEnv("ADMIN_LOCAL_ONLY", true),
  devShowPrivateCards: booleanEnv("DEV_SHOW_PRIVATE_CARDS", false),
};

function integerEnv(name: string, fallback: number): number {
  const value = Number(process.env[name]);
  return Number.isInteger(value) && value > 0 ? value : fallback;
}

function booleanEnv(name: string, fallback: boolean): boolean {
  const value = process.env[name];
  if (value === undefined || value === "") return fallback;
  return ["1", "true", "yes", "on"].includes(value.toLowerCase());
}

function databaseDriverEnv(value: string | undefined): DatabaseDriver {
  if (value === "postgres") return "postgres";
  return "sqlite";
}
