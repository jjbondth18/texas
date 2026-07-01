# Local Two Client Public Table Test

This is a development-only flow for testing two real Godot clients on one machine before Steam or a production account system exists.

## Start the Local Server

```bat
cd C:\Users\jjbon\Documents\texas\server
npm.cmd run dev
```

Both clients connect to the default local authoritative server:

```text
ws://127.0.0.1:8080
```

## Client A

Client A can use the normal local profile:

```bat
dev\run_client_1.bat
```

Default identity:

```text
player_id=local_player
player_name=Luna0581
save=user://save_data.json
```

## Client B

Client B uses a development identity override:

```bat
dev\run_client_2.bat
```

Equivalent command:

```bat
godot --path . -- --dev-player-id=dev_player_2 --dev-player-name=DevPlayer2 --dev-save-suffix=p2
```

Client B identity:

```text
player_id=dev_player_2
player_name=DevPlayer2
save=user://save_data_p2.json
```

You can also use environment variables instead of launch arguments:

```bat
set TEXAS_DEV_PLAYER_ID=dev_player_2
set TEXAS_DEV_PLAYER_NAME=DevPlayer2
set TEXAS_DEV_SAVE_SUFFIX=p2
godot --path .
```

Launch arguments take priority over environment variables.

## Confirm the Identity

When the poker table connects to the authoritative server, the table log prints:

```text
DEV IDENTITY
player_id=...
player_name=...
save_suffix=...
```

For Client B, confirm it says:

```text
player_id=dev_player_2
player_name=DevPlayer2
save_suffix=p2
```

## Public Table Test Flow

1. Start the local server.
2. Start Client A.
3. Client A creates a public table.
4. Client A may start AI Warm-up while waiting.
5. Start Client B with `dev\run_client_2.bat`.
6. Client B opens the Browser and joins Client A's public table.
7. Client A's local warm-up should stop and return to the real public room.
8. The server room should show both real websocket clients seated:
   - Luna0581
   - DevPlayer2
9. Client A clicks `START PUBLIC HAND`.
10. The official public hand starts with both clients as real players.
11. When it is Client B's turn, use Client B's window to act.

## Notes

- This is not a formal account system.
- This does not use Steam authentication.
- The server still uses `auth_provider=local_dev`.
- The important identity key is `external_id`, which comes from `--dev-player-id`.
- Different `dev_player_id` values map to different local dev identities on the server.
- Different `dev_save_suffix` values keep local save files separate during multi-client testing.
