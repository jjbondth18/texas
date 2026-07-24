# Local Admin audit and implementation

## Existing system

- Database: SQLite via `better-sqlite3`, WAL and foreign keys enabled. `SQLITE_PATH` / `TEXAS_DB_PATH` select the file; `DATABASE_URL` is reserved.
- Identity: `players.player_id`, Steam identity in `player_identities(provider='steam').external_id`, display names in `players.display_name` and `steam_persona_name`.
- Economy: `wallets.chips/gems`, `player_progression.total_xp`, `daily_login_claims`.
- All audited authoritative Chip/Gem mutations use `WalletRepository.adjustBalance()` and write `wallet_transactions`. Admin writes use their own transaction and produce both a compatible wallet transaction and `admin_audit_logs`.
- Matches are per-player settlement rows in `table_session_results`; no canonical match start/aborted fields exist.
- Replay data is split among `replay_index`, `replay_participants`, `replay_keys`, and `replay_unlocks`. There are no preview/blob columns. Key material is never selected by Admin.
- Deployment docs mention PM2 as an option but contain no committed PM2 ecosystem config. The game service defaults to `127.0.0.1:8080` and exposes `/healthz`.

## Architecture

The Admin is a separate Node HTTP entry point compiled by the existing server TypeScript build. It reuses the existing SQLite initialization/migrations, serves a dependency-free static UI, rejects non-loopback binding, and keeps PIN sessions in memory. SQL lives only in the repository layer and every write uses parameter binding and a transaction where multiple records change.

Phase 2 runs the Admin backend on the VM beside the production SQLite file. Windows forwards only the loopback HTTP port over SSH and never mounts or copies SQLite. Both server processes use WAL, foreign keys, and a bounded busy timeout. Admin startup requires an existing absolute database path, creates an online pre-migration backup, and stops on migration failure.
