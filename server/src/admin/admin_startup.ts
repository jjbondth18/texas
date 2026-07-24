import Database from "better-sqlite3";
import { existsSync, mkdirSync, realpathSync, statSync } from "node:fs";
import { basename, dirname, isAbsolute, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { initializeSchema } from "../db/schema.js";

const REQUIRED_TABLES = ["players", "wallets", "wallet_transactions", "player_progression", "admin_audit_logs"];

export interface AdminDatabaseOptions {
  sqlitePath: string;
  backupDir: string;
  nodeEnv: string;
  migrationRunner?: (db: Database.Database) => void;
  now?: Date;
}

export interface AdminDatabaseResult {
  db: Database.Database;
  databasePath: string;
  preMigrationBackup: string;
}

export async function openAdminDatabase(options: AdminDatabaseOptions): Promise<AdminDatabaseResult> {
  const databasePath = validateProductionDatabasePath(options.sqlitePath, options.nodeEnv);
  const backupDir = validateBackupDirectory(options.backupDir);
  const db = new Database(databasePath, { fileMustExist: true });
  try {
    db.pragma("journal_mode = WAL");
    db.pragma("foreign_keys = ON");
    db.pragma(`busy_timeout = ${busyTimeout()}`);
    const integrity = db.pragma("quick_check") as Array<{ quick_check?: string }>;
    if (integrity[0]?.quick_check !== "ok") throw new Error("SQLite quick_check failed before migration");
    const stamp = (options.now ?? new Date()).toISOString().replace(/[:.]/g, "-");
    const preMigrationBackup = join(backupDir, `pre-migration-${stamp}.sqlite`);
    await db.backup(preMigrationBackup);
    try {
      (options.migrationRunner ?? initializeSchema)(db);
    } catch (error) {
      throw new Error(`Admin migration failed; startup stopped. Pre-migration backup: ${preMigrationBackup}. ${message(error)}`);
    }
    assertRequiredTables(db);
    return { db, databasePath, preMigrationBackup };
  } catch (error) {
    db.close();
    throw error;
  }
}

export function validateProductionDatabasePath(path: string, nodeEnv: string): string {
  if (!path || !isAbsolute(path)) throw new Error("SQLITE_PATH must be an absolute path");
  const normalized = resolve(path);
  if (!existsSync(normalized) || !statSync(normalized).isFile()) throw new Error(`Production SQLite database does not exist: ${normalized}`);
  if (!existsSync(dirname(normalized)) || !statSync(dirname(normalized)).isDirectory()) throw new Error("SQLite parent directory does not exist");
  const lower = basename(normalized).toLowerCase();
  if (/(^|[._-])(test|tests|smoke|temp|tmp)([._-]|$)/.test(lower)) throw new Error(`Refusing test or temporary SQLite database: ${lower}`);
  const real = realpathSync(normalized);
  const temp = realpathSync(tmpdir());
  if (real === temp || real.startsWith(temp.endsWith("\\") || temp.endsWith("/") ? temp : `${temp}\\`) || real.startsWith(`${temp}/`)) {
    throw new Error("Refusing SQLite database inside the operating-system temporary directory");
  }
  if (nodeEnv === "production" && normalized === ":memory:") throw new Error("Production Admin cannot use an in-memory database");
  return real;
}

export function validateBackupDirectory(path: string): string {
  if (!path || !isAbsolute(path)) throw new Error("ADMIN_BACKUP_DIR must be an absolute path");
  const normalized = resolve(path);
  mkdirSync(normalized, { recursive: true });
  if (!statSync(normalized).isDirectory()) throw new Error("ADMIN_BACKUP_DIR is not a directory");
  return normalized;
}

export function assertRequiredTables(db: Database.Database): void {
  const rows = db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all() as Array<{ name: string }>;
  const names = new Set(rows.map((row) => row.name));
  const missing = REQUIRED_TABLES.filter((name) => !names.has(name));
  if (missing.length) throw new Error(`Admin required tables are missing: ${missing.join(", ")}`);
}

function busyTimeout(): number {
  const value = Number(process.env.SQLITE_BUSY_TIMEOUT_MS);
  return Number.isInteger(value) && value >= 1000 && value <= 60000 ? value : 5000;
}

function message(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
