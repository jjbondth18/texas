# Server Deployment Guide

This guide prepares the local authoritative poker server for VPS or Google Cloud VM style deployment. It does not cover managed cloud deployment, Steam SDK integration, real-money payments, or production operations.

## Local Production Simulation

From the repository root:

```bat
cd server
npm install
npm run build
npm run start
```

`npm run start` runs the compiled `dist/index.js` server and reads configuration from environment variables.

## Windows Local Environment Test

In `cmd.exe`:

```bat
cd server
set PORT=8080
set HOST=0.0.0.0
npm run build
npm run start
```

For local Godot development, `HOST=127.0.0.1` is usually safer. Use `HOST=0.0.0.0` only when testing access from another device or VM.

## Linux VPS / Google Cloud VM Outline

1. Install Node.js LTS.
2. Clone or upload the project.
3. Enter the server directory:

```sh
cd server
npm ci
npm run build
cp .env.example .env
```

4. Edit `.env` and set a persistent database path, for example:

```env
SQLITE_PATH=/var/lib/texas-poker/texas.sqlite
```

5. Start the compiled server:

```sh
npm run start
```

For long-running hosting, use a process manager such as systemd or pm2. Keep the SQLite directory persistent and backed up.

## Firewall And Ports

Port `8080` currently serves:

- WebSocket poker traffic
- `/admin` local debug dashboard
- `/admin/db` read-only database debug page
- `/healthz` health check

Production-like deployments should expose only necessary ports. The admin pages have no formal authentication, so protect them with firewall rules, a VPN, or a reverse proxy with authentication before exposing the server publicly.

## Godot Server URL

Godot defaults to the local development server:

```text
ws://127.0.0.1:8080
```

For a VM or VPS test, set a temporary environment variable before launching Godot:

```text
TEXAS_SERVER_URL=ws://104.197.125.248:8080
```

Future HTTPS deployments should use:

```text
wss://your-domain
```

The Godot client resolves the server URL in this order:

1. `TEXAS_SERVER_URL`
2. `texas/network/server_url`
3. `ws://127.0.0.1:8080`

Do not commit a public server IP as the code default.

## SQLite Production Warning

SQLite is acceptable for early single-instance testing and local development. It is not the intended long-term database for multi-instance hosting or formal operations.

Before production operation:

- Move account and wallet data to PostgreSQL.
- Back up the SQLite file if you are still using it for tests.
- Keep `SQLITE_PATH` outside the repository, such as `/var/lib/texas-poker/texas.sqlite`.

## Admin Security Warning

The current admin dashboard is for local development. It is read-only for database inspection, but it has no production authentication.

Do not expose `/admin` or `/admin/db` directly on the public internet without adding authentication or strict network controls.
