import type Database from "better-sqlite3";
import { migration001InitialSchema } from "./migrations/001_initial_schema.js";
import { migration002WalletTransactions } from "./migrations/002_wallet_transactions.js";
import { migration003ReplayMetadata } from "./migrations/003_replay_metadata.js";
import { migration004ReplayUnlocks } from "./migrations/004_replay_unlocks.js";

interface Migration {
  id: string;
  up(db: Database.Database): void;
}

const migrations: Migration[] = [migration001InitialSchema, migration002WalletTransactions, migration003ReplayMetadata, migration004ReplayUnlocks];

export function runMigrations(db: Database.Database): void {
  db.exec(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id TEXT PRIMARY KEY,
      applied_at TEXT NOT NULL
    );
  `);

  const appliedRows = db.prepare("SELECT id FROM schema_migrations").all() as Array<{ id: string }>;
  const applied = new Set(appliedRows.map((row) => row.id));
  const applyMigration = db.transaction((migration: Migration) => {
    migration.up(db);
    db.prepare("INSERT OR IGNORE INTO schema_migrations (id, applied_at) VALUES (?, ?)").run(migration.id, new Date().toISOString());
  });

  for (const migration of migrations) {
    if (!applied.has(migration.id)) applyMigration(migration);
  }
}
