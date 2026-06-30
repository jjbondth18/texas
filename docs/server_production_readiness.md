# Server Production Readiness

This document tracks the server architecture work needed before any public release. It is not a deployment guide and does not describe real-money payments.

## Current Dev Architecture

- Node.js + TypeScript WebSocket server.
- Local authoritative poker rules, room lifecycle, wallet/table chips, avatar unlocks, lobby table list, and bots.
- SQLite development database at `server/data/texas_dev.sqlite` by default.
- Local-only admin debug pages at `/admin` and `/admin/db`.
- Godot clients render snapshots and send requests; they do not decide poker outcomes.

## Future Production Architecture

- Keep the Node.js authoritative server boundary.
- Run behind a managed reverse proxy or cloud load balancer with TLS.
- Replace local SQLite with PostgreSQL.
- Store credentials and deployment secrets in platform secret storage, not in the repo.
- Treat admin routes as internal-only or protect them with real operator authentication before production.

## SQLite To PostgreSQL Plan

The current repository interfaces are intentionally small: players, identities, wallets, wallet transactions, daily login claims, avatar unlocks, and hand results.

Before production:

1. Add a PostgreSQL driver implementation behind the database boundary.
2. Convert migrations to SQL that can run on PostgreSQL.
3. Preserve `schema_migrations` ids so deploys are repeatable.
4. Run migration dry-runs against a staging PostgreSQL database.
5. Backfill or export any local dev data only when explicitly needed.

SQLite remains supported for local development.

## Steam Identity Plan

The `player_identities` table separates a local player from an external identity:

- Current local dev provider: `local_dev`
- Future Steam provider: `steam`
- Future Steam external id: Steam ID from verified Steam auth

Before production Steam login:

1. Verify Steam auth server-side.
2. Link or create a player from `(provider, external_id)`.
3. Stop trusting client-supplied names or ids as identity proof.
4. Keep display name/avatar as profile data, not authentication data.

## Required Environment Variables

- `NODE_ENV`
- `HOST`
- `PORT`
- `DATABASE_DRIVER`
- `SQLITE_PATH`
- `DATABASE_URL`
- `ADMIN_ENABLED`
- `ADMIN_LOCAL_ONLY`
- `DEV_SHOW_PRIVATE_CARDS`

`DATABASE_DRIVER=sqlite` is the only implemented driver today. `DATABASE_DRIVER=postgres` is reserved and intentionally fails until PostgreSQL wiring is added.

## Must Finish Before Public Release

- Production identity verification, such as Steam auth.
- PostgreSQL persistence and tested deploy migrations.
- TLS and secure WebSocket hosting.
- Rate limits and request validation hardening.
- Anti-cheat and reconnect policy hardening.
- Operator authentication for admin pages or complete removal from public deployments.
- Observability: structured logs, metrics, alerts, and crash reporting.
- Backup/restore plan for production database.
- Load testing with realistic concurrent rooms.
- Security review of wallet and table-chip transitions.

## Why This Is Not Production Yet

- SQLite is local dev storage.
- Admin pages have no real authentication and are only suitable for local development.
- Identity is still local-dev identity, not verified Steam identity.
- No cloud deployment, TLS, scaling, or operational monitoring exists.
- No production incident, backup, or migration process exists.
- No real-money purchase or payment flow is implemented.
