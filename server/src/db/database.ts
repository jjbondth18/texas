import Database from "better-sqlite3";
import { mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { initializeSchema } from "./schema.js";

const moduleDir = dirname(fileURLToPath(import.meta.url));
const defaultDatabasePath = resolve(moduleDir, "../../data/texas_dev.sqlite");

let sharedDatabase: Database.Database | null = null;

export function databasePath(): string {
  return process.env.TEXAS_DB_PATH || defaultDatabasePath;
}

export function openDatabase(path = databasePath()): Database.Database {
  mkdirSync(dirname(path), { recursive: true });
  const db = new Database(path);
  db.pragma("journal_mode = WAL");
  db.pragma("foreign_keys = ON");
  initializeSchema(db);
  return db;
}

export function getDatabase(): Database.Database {
  if (!sharedDatabase) sharedDatabase = openDatabase();
  return sharedDatabase;
}

export function closeDatabase(): void {
  if (!sharedDatabase) return;
  sharedDatabase.close();
  sharedDatabase = null;
}
