import type Database from "better-sqlite3";

export const migration012SteamCommerce = {
  id: "012_steam_commerce",
  up(db: Database.Database): void {
    db.exec(`
      CREATE TABLE IF NOT EXISTS steam_purchase_orders (
        order_id TEXT PRIMARY KEY,
        player_id TEXT NOT NULL,
        steam_id TEXT NOT NULL,
        package_id TEXT NOT NULL,
        package_title TEXT NOT NULL,
        chips_amount INTEGER NOT NULL,
        gems_amount INTEGER NOT NULL,
        price_minor INTEGER NOT NULL,
        price_currency TEXT NOT NULL,
        environment TEXT NOT NULL,
        status TEXT NOT NULL,
        idempotency_key TEXT NOT NULL,
        steam_trans_id TEXT,
        created_at TEXT NOT NULL,
        initialized_at TEXT,
        authorized_at TEXT,
        finalized_at TEXT,
        granted_at TEXT,
        cancelled_at TEXT,
        failed_at TEXT,
        failure_code TEXT,
        failure_message TEXT,
        FOREIGN KEY(player_id) REFERENCES players(player_id),
        UNIQUE(player_id, idempotency_key)
      );

      CREATE INDEX IF NOT EXISTS idx_steam_purchase_orders_player_created
        ON steam_purchase_orders(player_id, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_steam_purchase_orders_status
        ON steam_purchase_orders(status);
    `);

    const walletColumns = db.prepare("PRAGMA table_info(wallet_transactions)").all() as Array<{ name: string }>;
    if (!walletColumns.some((column) => column.name === "reference_id")) {
      db.exec("ALTER TABLE wallet_transactions ADD COLUMN reference_id TEXT");
    }
    if (!walletColumns.some((column) => column.name === "display_label")) {
      db.exec("ALTER TABLE wallet_transactions ADD COLUMN display_label TEXT");
    }
    db.exec("CREATE INDEX IF NOT EXISTS idx_wallet_transactions_reference ON wallet_transactions(reference_id)");
  },
};
