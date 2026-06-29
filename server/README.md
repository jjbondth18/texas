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

## Local Test Bots

When Godot F6 can only keep one client window open, run local bots to fill seats in the same room:

```powershell
npm.cmd run bot -- --room room_1 --count 2 --start-seat 1 --action-delay-ms 700
```

Defaults:

```text
url: ws://127.0.0.1:8080
count: 2
start-seat: 1
action-delay-ms: 650
```

Each bot sends `hello`, `join_room`, `sit_down`, and `ready`. On its turn it waits for the configured action delay plus a small jitter, then checks when possible, otherwise calls, otherwise folds. Bots are only for local development testing.

## Official Godot Table Local Multiplayer Test

1. Start the authoritative server:

   ```powershell
   cd C:\Users\jjbon\Documents\texas\server
   npm.cmd run dev
   ```

2. Open the local admin dashboard:

   ```text
   http://127.0.0.1:8080/admin
   ```

3. Run the official Godot poker table screen or the normal project entry. The table uses `server_authoritative = true` by default and connects to `ws://127.0.0.1:8080`.

4. Read the `room_id` from the Godot table log or UI debug output.

5. Start local bots in that room:

   ```powershell
   cd C:\Users\jjbon\Documents\texas\server
   npm.cmd run bot -- --room <room_id> --count 2 --start-seat 1 --action-delay-ms 700
   ```

6. Start a hand from the Godot table, then play through preflop, flop, turn, river, showdown, and settlement. The Godot client must only render snapshots and send player actions; shuffling, dealing, betting validation, pots, winners, and chip settlement come from the server.

## Official Table UI Parity Checklist

Use this while testing the server-authoritative table:

1. Confirm each occupied seat shows the latest server action, such as `Check`, `Call 50`, `Raise 200`, `Fold`, `All-in`, `Small Blind`, or `Big Blind`.
2. Confirm the bottom action area says `Your Turn` only for the local player's turn, otherwise `Waiting for <player>`.
3. Confirm Fold, Check/Call, Bet/Raise, and All-in are clickable only when the server private snapshot lists them as legal actions.
4. Confirm Table Log updates from the server `recent_actions` / `action_log`, including blinds, player actions, street changes, and winners.
5. Confirm bots acting through `npm.cmd run bot -- --room <room_id> --count 2 --start-seat 1 --action-delay-ms 700` are reflected in the Godot seats, Table Log, and `http://127.0.0.1:8080/admin`.
6. If the table is waiting with enough ready players, press `S` in the Godot table to request `start_hand`.

## Server Action Pacing Test

1. Start the server with `npm.cmd run dev`.
2. Open `http://127.0.0.1:8080/admin`.
3. Run the official Godot poker table and copy the `room_id` from the Table Log.
4. Start bots with:

   ```powershell
   npm.cmd run bot -- --room <room_id> --count 2 --start-seat 1 --action-delay-ms 700
   ```

5. Start a hand, click a player action, and confirm bot actions arrive with short spacing instead of all in one frame.
6. Confirm Godot shows seat action labels and Table Log entries one by one, and public cards no longer appear in the same frame as every pending action.
