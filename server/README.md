# Local Poker Server

This server is for local development only. It binds to `127.0.0.1` by default and should not be exposed to the public internet.

It does not implement production accounts, database storage, payments, billing, Google Cloud deployment, or formal GM operations.

## Run

```powershell
npm install
npm.cmd run dev
```

WebSocket clients connect to:

```text
ws://127.0.0.1:8080
```

## Admin Debug Dashboard

Open the local-only dashboard:

```text
http://127.0.0.1:8080/admin
```

The dashboard shows uptime, active WebSocket connections, room count, rooms, seats, hand state, betting round, pot, side pots, community cards, current turn seat, and recent server logs.

Private hole cards are hidden by default. For one-off local debugging only, start the server with:

```powershell
$env:DEV_SHOW_PRIVATE_CARDS="true"
npm.cmd run dev
```

Do not use `DEV_SHOW_PRIVATE_CARDS=true` outside local development.
