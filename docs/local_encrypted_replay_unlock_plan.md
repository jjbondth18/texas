# Local Encrypted Replay Unlock Plan

This document defines the planned replay unlock architecture for official server rooms. It is design-only. It does not implement Steam, server replay storage, UI changes, or room/table refactors.

## Current Problems

The current replay flow is convenient for local development but not suitable for an official server economy:

- At `hand_over`, the server builds a full `replay_record`.
- The full `replay_record` includes every seated player's `hole_cards`.
- The full record is attached to `table_snapshot.replay_record` and broadcast to room clients.
- The Godot client saves replay files under `user://replays/` as plain JSON.
- The Replay UI lock is only a UI/profile gate. The underlying replay JSON is readable.
- `ProfileService.unlock_replay()` currently deducts gems locally, which is not trustworthy for an authoritative economy.
- The server does not currently have `unlock_replay`, `replay_unlocks`, `replay_keys`, or `replay_participants`.

The key issue is that a locked replay cannot be protected if the complete replay, including all private cards, is stored locally as plaintext and unlock only happens in local profile state.

## Target Architecture

Use a local encrypted replay blob with server-controlled unlock authority:

- Godot still stores replay content locally.
- The server does not store the complete replay `record_json`.
- Official server-room replay private data is encrypted before it is persisted locally.
- The server stores only replay metadata, participant ACL, unlock status, and replay key material.
- Unlocking is authoritative: gems are deducted on the server, recorded in `wallet_transactions`, and protected by an idempotent unlock table.
- Without a server-returned replay key, the official client cannot decrypt and play the full replay.

High-level components:

- Local encrypted replay blob
- Server replay metadata
- Server participant ACL
- Server unlock transaction
- Server replay key return

## Local File Structure

Recommended Godot local replay layout:

```text
user://replays/<replay_id>/
  metadata.json
  public_preview.json
  private.enc
  unlock.json
```

### metadata.json

Plaintext. Used for list/detail display before unlock.

Allowed fields:

- `replay_id`
- `created_at`
- `ended_at`
- `hand_id`
- `room_id`
- `room_code`
- `table_type`
- `currency`
- `buy_in`
- `small_blind`
- `big_blind`
- `hand_number`
- `max_hands`
- `player_names`
- `seat_indices`
- `final_chip_delta`
- `final_gem_delta`
- `dealer_id`
- `dealer_thumbnail`
- `locked`
- `schema_version`
- `checksum`

### public_preview.json

Optional plaintext. Used for locked replay preview.

Allowed fields:

- Public board cards if the hand is over
- Public action summary
- Winner names/seats if already public at showdown/hand over
- Final pot
- Player names/seats
- Dealer thumbnail
- Result summary

Do not include:

- Hidden hole cards
- Full private snapshots
- Full replay playback state if it reveals private information
- Equity table inputs that require hidden hole cards

### private.enc

Encrypted. Contains everything needed by Replay Table View playback.

Contains:

- Full replay table view data
- All player `hole_cards`
- Showdown data
- Equity table data inputs
- Complete action log
- Full board progression
- Private/player state snapshots needed for playback

### unlock.json

Local cache only. Not authoritative.

Possible fields:

- `replay_id`
- `unlocked_locally`
- `key_version`
- `unlock_token`
- `unlocked_at`
- `last_verified_at`

Rules:

- This file can improve UX and avoid repeated local prompts.
- It must not be trusted as proof of purchase.
- Official playback should be able to revalidate with the server when needed.

## Server Database Draft

The server must not store the full replay record JSON. It should store metadata, participants, key material, and unlock state.

### replay_index

```text
replay_id TEXT PRIMARY KEY
hand_id TEXT NOT NULL
room_id TEXT NOT NULL
room_code TEXT
table_type TEXT NOT NULL
currency TEXT NOT NULL
created_at TEXT NOT NULL
checksum TEXT NOT NULL
schema_version INTEGER NOT NULL
```

Purpose:

- Identify an official replay.
- Allow participant lookup and key lookup.
- Support list/detail metadata reconciliation.
- Verify the local encrypted blob checksum.

### replay_participants

```text
replay_id TEXT NOT NULL
player_id TEXT NOT NULL
seat_index INTEGER NOT NULL
PRIMARY KEY (replay_id, player_id)
```

Purpose:

- Enforce "only players who participated can unlock/view this replay".
- Support future per-player reveal policies.

### replay_keys

```text
replay_id TEXT PRIMARY KEY
key_material TEXT NOT NULL
key_version INTEGER NOT NULL
created_at TEXT NOT NULL
```

Alternative:

- Store `encrypted_key_material` instead of raw `key_material` if server-side key wrapping is introduced.

Purpose:

- Server can return the replay key after ACL and unlock checks.
- Key rotation can be represented by `key_version`.

### replay_unlocks

```text
replay_id TEXT NOT NULL
player_id TEXT NOT NULL
currency TEXT NOT NULL
cost INTEGER NOT NULL
transaction_id TEXT NOT NULL
unlocked_at TEXT NOT NULL
PRIMARY KEY (replay_id, player_id)
```

Purpose:

- Idempotent unlock record.
- Prevent repeat gem deductions.
- Link gem spend to `wallet_transactions`.

## New hand_over Flow

The current flow should change so the full replay is never broadcast or saved as plaintext in official server mode.

New flow:

1. `buildHandReplayRecord()` may still generate the full record internally on the server at `hand_over`.
2. Server generates a `replay_id`.
3. Server generates a `replay_key`.
4. Server encrypts the full record into `private.enc`.
5. Server generates `metadata.json` and optional `public_preview.json`.
6. Server computes a checksum for the encrypted private blob.
7. Server saves:
   - `replay_index`
   - `replay_participants`
   - `replay_keys`
8. Server sends only these replay delivery fields to room clients:
   - metadata
   - public preview
   - encrypted private blob
   - checksum
   - key version
9. Client writes:
   - `metadata.json`
   - `public_preview.json`
   - `private.enc`
10. Client does not receive the replay key during normal hand over.
11. Until unlock succeeds, the client cannot decrypt `private.enc`.

Important replacement:

- Do not attach full plaintext `replay_record` to `table_snapshot`.
- Use either a dedicated `replay_saved` / `encrypted_replay_ready` message or a safe `table_snapshot.replay_metadata` payload.

## unlock_replay Flow

Client request:

```text
unlock_replay(replay_id)
```

Server flow:

1. Resolve canonical `player_id` from the connection/session.
2. Verify `replay_id` exists in `replay_index`.
3. Verify `player_id` exists in `replay_participants` for this replay.
4. Check `replay_unlocks` for `(replay_id, player_id)`.
5. If already unlocked:
   - Do not deduct gems.
   - Return `replay_key`, `key_version`, and `checksum`.
6. If not unlocked:
   - Check wallet gems >= replay unlock cost.
   - Deduct gems through authoritative wallet code.
   - Write `wallet_transactions` with `reason = replay_unlock`.
   - Write `replay_unlocks`.
   - Return `replay_key`, `key_version`, and `checksum`.
7. Client uses `replay_key` to decrypt local `private.enc`.
8. Client opens Replay Table View from decrypted replay data.

Failure cases:

- Not participant: return `replay_access_denied`.
- Missing replay: return `replay_not_found`.
- Missing encrypted local blob: client shows "Replay file missing".
- Not enough gems: return `insufficient_gems`.
- Checksum mismatch: return/use `replay_checksum_mismatch` and do not play.

## Training and Local Replay Compatibility

Training and local-only practice flows can remain simpler:

- Training replay may continue as local-only plaintext JSON, or it can be separately marked `local_only`.
- Local warm-up replay may remain local-only if it is not an official server-room hand.
- Official public/private server-room replay must use encrypted local storage.
- Local mock/dev mode can keep the old plaintext replay path for development, but it must not be used for official server mode.

Recommended metadata flag:

```json
{
  "storage_mode": "official_encrypted"
}
```

or

```json
{
  "storage_mode": "local_only_plaintext"
}
```

## Security Boundary

This design is not 100% anti-crack DRM.

It is intended to:

- Prevent ordinary players from opening full official replay data through the client before paying gems.
- Avoid local plaintext replay files exposing all `hole_cards`.
- Move gem spending and replay unlock authority to the server.
- Prevent repeated gem deductions for the same replay.
- Keep complete replay payloads out of the server database.

It does not fully prevent:

- Advanced reverse engineering.
- Memory inspection after a replay is decrypted.
- Sharing decrypted replay data or replay keys.
- Modified clients.

Future hardening options:

- Server key wrapping.
- Short-lived unlock tokens.
- Per-account encrypted keys.
- Device-bound cache tokens.
- Replay watermarking.
- Delayed reveal policies for certain modes.

## Minimal Patch Split

### Patch 2: server encrypted replay emit

Scope:

- Add replay metadata/key/participant tables.
- Generate `replay_id` and `replay_key` at `hand_over`.
- Encrypt full replay record into an encrypted private blob.
- Stop broadcasting plaintext private replay data.
- Send metadata, public preview, encrypted blob, checksum, and key version.
- Client saves encrypted replay file structure.
- Do not implement gem unlock yet.

Likely files:

- `server/src/replay.ts`
- `server/src/room_manager.ts`
- `server/src/protocol.ts`
- `server/src/db/migrations/*.ts`
- New `server/src/db/replay_repository.ts`
- `scripts/replay/replay_repository.gd`
- `scripts/screens/poker_table_screen.gd`

Acceptance:

- Official server hand-over no longer writes plaintext full replay JSON.
- `private.enc` exists locally.
- Metadata/preview are readable.
- Replay Detail can show locked preview.
- Full playback remains unavailable until unlock.

### Patch 3: server unlock_replay

Scope:

- Add `unlock_replay` websocket command.
- Enforce participant ACL.
- Check idempotent `replay_unlocks`.
- Deduct gems server-side.
- Write `wallet_transactions.reason = replay_unlock`.
- Return replay key/key version/checksum.
- Do not duplicate charge on repeat unlock.

Likely files:

- `server/src/protocol.ts`
- `server/src/room_manager.ts`
- `server/src/db/replay_repository.ts`
- `server/src/db/wallet_repository.ts`
- `scripts/network/poker_protocol.gd`
- `scripts/network/poker_ws_client.gd`
- `scripts/services/profile_service.gd`
- `scripts/screens/home_lobby_screen.gd`

Acceptance:

- Non-participant cannot unlock.
- Participant can unlock if gems are sufficient.
- Repeated unlock returns key without charging again.
- Wallet and top bar sync from server.

### Patch 4: client replay playback integration

Scope:

- Replay Detail uses plaintext metadata and preview while locked.
- Unlock button calls server in official mode.
- On success, client decrypts `private.enc`.
- Replay Table View receives decrypted data.
- Already unlocked replay can be played again.
- `local_only` replay keeps existing local behavior.

Likely files:

- `scripts/replay/replay_repository.gd`
- `scripts/services/replay_service.gd`
- `scripts/services/profile_service.gd`
- `scripts/screens/home_lobby_screen.gd`
- `scripts/screens/replay_poker_table_screen.gd`

Acceptance:

- Locked official replay cannot play without server key.
- Local-only/training replay still opens with old local path.
- Unlock failure does not mutate local unlock state.
- Checksum mismatch blocks playback.

## Non-goals

- Do not upload full replay `record_json` to the server database.
- Do not implement full cloud replay storage.
- Do not integrate Steam.
- Do not redesign Replay UI visuals.
- Do not refactor room/table gameplay systems.
- Do not change poker rules, settlement, or table economy in this plan.
