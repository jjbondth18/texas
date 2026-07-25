import type Database from "better-sqlite3";
import { migration001InitialSchema } from "./migrations/001_initial_schema.js";
import { migration002WalletTransactions } from "./migrations/002_wallet_transactions.js";
import { migration003ReplayMetadata } from "./migrations/003_replay_metadata.js";
import { migration004ReplayUnlocks } from "./migrations/004_replay_unlocks.js";
import { migration005TableBalances } from "./migrations/005_table_balances.js";
import { migration006PlayerProfileBootstrap } from "./migrations/006_player_profile_bootstrap.js";
import { migration007HandStatisticsEvents } from "./migrations/007_hand_statistics_events.js";
import { migration008PlayerProfileBackfill } from "./migrations/008_player_profile_backfill.js";
import { migration009ReplayEconomy } from "./migrations/009_replay_economy.js";
import { migration010PlayerDisplayName } from "./migrations/010_player_display_name.js";
import { migration011ReplayIdentityIntegrity } from "./migrations/011_replay_identity_integrity.js";
import { migration012SteamCommerce } from "./migrations/012_steam_commerce.js";
import { migration013LocalAdmin } from "./migrations/013_local_admin.js";
import { migration014VirtualPlayerRuntime } from "./migrations/014_virtual_player_runtime.js";

interface Migration {
  id: string;
  up(db: Database.Database): void;
}

const migrations: Migration[] = [
  migration001InitialSchema,
  migration002WalletTransactions,
  migration003ReplayMetadata,
  migration004ReplayUnlocks,
  migration005TableBalances,
  migration006PlayerProfileBootstrap,
  migration007HandStatisticsEvents,
  migration008PlayerProfileBackfill,
  migration009ReplayEconomy,
  migration010PlayerDisplayName,
  migration011ReplayIdentityIntegrity,
  migration012SteamCommerce,
  migration013LocalAdmin,
  migration014VirtualPlayerRuntime,
];

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
