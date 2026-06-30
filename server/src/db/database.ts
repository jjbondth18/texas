import Database from "better-sqlite3";
import { mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { config } from "../config.js";
import { initializeSchema } from "./schema.js";

let sharedDatabase: Database.Database | null = null;

export function databasePath(): string {
  return process.env.SQLITE_PATH || process.env.TEXAS_DB_PATH || config.sqlitePath;
}

export function openDatabase(path = databasePath()): Database.Database {
  // Development currently uses SQLite so local runs stay zero-dependency.
  // Production should move this boundary to a PostgreSQL implementation
  // behind the same repository interfaces before public deployment.
  if (config.databaseDriver !== "sqlite") {
    throw new Error("DATABASE_DRIVER=postgres is reserved for production wiring; this build only opens SQLite.");
  }
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
