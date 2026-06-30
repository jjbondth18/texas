# Store Mock Purchase and Server Wallet

This project currently supports development-only Store wallet packs. They are not real payments.

## Authoritative Server Mode

When the Godot client is connected to the local authoritative server, Store mock purchases send a WebSocket `mock_purchase` command:

- `currency`: `chips` or `gems`
- `amount`: selected mock pack amount
- `source`: `store_mock`

The server updates the canonical wallet in SQLite, writes a `wallet_transactions` row with reason `store_mock_purchase`, and returns wallet sync messages. Godot then updates `ProfileService`, the Home TopBar, Store/Profile panels, and Quick/Public setup affordability from the server wallet.

This means public table buy-in checks and `sit_down` validation both use the same authoritative wallet balance.

## Local / Offline Mode

If the client is not connected to the authoritative server, Store mock purchases keep using the local `StoreMockService` / `ProfileService` fallback so existing local mock flows remain usable.

## Dev Only

Store mock purchases must remain labeled:

- `MOCK PURCHASE`
- `DEV ONLY`

The server uses `ALLOW_MOCK_PURCHASES` to control this feature. Development defaults to enabled; production deployments should keep it disabled.

## Not Real Payment

This does not implement Stripe, Steam purchases, platform billing, order records, or receipt validation. Future real-money flows must validate platform receipts server-side before changing the authoritative wallet.
