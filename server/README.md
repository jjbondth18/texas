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

## Server Next Hand Flow Test

1. Play one server-authoritative hand through `hand_over`.
2. Confirm the Godot Table Log shows the winner rows and stack changes, for example `Luna wins 120` and `Luna stack 5000 -> 5120 (+120)`.
3. Confirm the bottom action prompt says `Hand Over - Press S to Start Next Hand`.
4. Press `S` to request the next hand without restarting the server or bots.
5. Confirm the new hand starts with empty community cards, cleared action labels, pot reset then blinds posted, inherited chip stacks, and rotated dealer / small blind / big blind seats.
6. Confirm existing bots continue to act in the second hand.

## Local Player Database

This development server uses a local SQLite database at:

```text
server/data/texas_dev.sqlite
```

The database is local development state only. It is not a production account system, does not store emails or passwords, and is not connected to Steam, payments, orders, rankings, or any cloud database. The schema can later migrate to PostgreSQL when real backend deployment starts.

On `hello`, the server creates or updates the local player profile, creates a wallet with `10000` starting chips, unlocks the default avatar, and automatically grants the first daily login bonus for the current UTC date (`+1000` chips). Repeating `hello` on the same day does not grant the bonus again.

To reset local development data, stop the server, delete `server/data/texas_dev.sqlite`, and restart `npm.cmd run dev`.

When Godot connects to the local server, the `hello` response includes the server profile, wallet, unlocked avatars, and daily login result. Godot applies those values to the local `ProfileService` cache so the lobby/top bar and table wallet displays prefer the SQLite-backed chips, gems, player name, and selected avatar. The first `hello` for a UTC day shows a lightweight `Daily bonus +1000 chips` message; reconnecting on the same UTC day does not award or display another bonus.

Wallet chips and table chips are separate local development balances:

- `wallet.chips` is the account-style balance stored in SQLite.
- `seat.chips` / table chips are the chips currently committed to a table seat.
- `sit_down` uses a fixed local-dev buy-in of `1000` chips. The server deducts that amount from `wallet.chips` and puts it on the seat as table chips. Client-provided buy-in values are ignored in this first version.
- `add_table_chips` moves chips from the server wallet to the seated player's table stack. It is not a purchase or recharge, and it is only allowed while the table is waiting or between hands.
- `cash_out` / `leave_seat` moves remaining table chips back to the server wallet and clears the seat. It is not allowed during an active hand in this first version.
- Hand results only change table chips. The wallet is updated later when the player cashes out.

This local wallet system still has no real-money payment, recharge, order, Store, Steam, ranking, cloud deployment, or production account flow.

Local profile sync test:

1. Start the server:

   ```powershell
   cd C:\Users\jjbon\Documents\texas\server
   npm.cmd run dev
   ```

2. To reset the local database, stop the server and delete:

   ```text
   C:\Users\jjbon\Documents\texas\server\data\texas_dev.sqlite
   ```

3. Run Godot and connect through the official server-authoritative table or the Local Server Test panel.
4. Confirm the Godot log shows the server profile/wallet sync and, on the first UTC-day connection, `Daily bonus +1000 chips`.
5. Return to the lobby and confirm the top bar/profile panel show the server wallet chips, gems, player name, and avatar. Reconnect on the same UTC day and confirm the daily bonus is not repeated.

Database smoke test:

```powershell
cd C:\Users\jjbon\Documents\texas\server
npm.cmd run db:smoke
```
