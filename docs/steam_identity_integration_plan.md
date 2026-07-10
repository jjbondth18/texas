# Steam Identity Integration Plan

This document is a preparation plan only. It does not add Steam Lobby, Steam P2P, Steam payment, replay changes, poker rule changes, or deployment changes.

## Current Identity System Audit

### Godot client

Relevant files:

- `scripts/services/identity_service.gd`
- `scripts/network/poker_protocol.gd`
- `scripts/network/poker_ws_client.gd`
- `scripts/services/profile_service.gd`

`IdentityService.get_identity()` currently resolves a local development identity. The returned payload contains:

- `provider`: currently always `local_dev`
- `external_id`: the local profile id, or the `--dev-player-id` / `TEXAS_DEV_PLAYER_ID` override
- `display_name`: local profile name, or the `--dev-player-name` / `TEXAS_DEV_PLAYER_NAME` override
- `avatar_id`
- `save_suffix`
- `has_dev_override`

`PokerWsClient.send_hello()` calls `IdentityService.get_identity()` and builds the server hello through `PokerProtocol.hello()`.

The hello payload currently supports:

- `auth_provider`
- `external_id`
- `external_player_id` compatibility alias
- `dev_player_id` compatibility alias for `local_dev`
- `player_id`
- `name`
- `player_name`
- `avatar_id`

Current default flow:

```text
IdentityService -> provider=local_dev -> PokerProtocol.hello -> server hello
```

There is no GodotSteam wrapper yet. There is no runtime Steam availability check yet. There is no Steam auth ticket collection yet.

### Server

Relevant files:

- `server/src/protocol.ts`
- `server/src/room_manager.ts`
- `server/src/db/player_repository.ts`
- `server/src/db/identity_repository.ts`
- `server/src/db/migrations/001_initial_schema.ts`
- `server/src/db_smoke_test.ts`

`protocol.ts` already allows hello messages to include:

- `auth_provider`
- `external_id`
- `name`
- `player_name`
- `avatar_id`

`room_manager.ts` has:

```ts
const ALLOWED_IDENTITY_PROVIDERS = new Set(["local_dev", "steam"]);
```

`RoomManager.handleHello()` calls `resolveIdentity()`.

`resolveIdentity()` behavior:

- Normalizes `auth_provider`, defaulting to `local_dev`.
- Rejects providers not in `local_dev` / `steam`.
- Uses `external_id` if present, otherwise `player_id` or fallback client id.
- Requires a non-empty external id.
- Looks up `player_identities(provider, external_id)`.
- If found, returns the existing internal `player_id`.
- If new:
  - `local_dev` maps internal `player_id` to a sanitized external id.
  - non-local providers such as `steam` receive an internal id like `player_<uuid>`.

`handleHello()` then:

- Upserts `players(player_id, display_name, avatar_id, ...)`.
- Ensures wallet.
- Links `player_identities(player_id, provider, external_id)`.
- Unlocks default avatar.
- Returns `server_player_id`, `profile`, `wallet`, unlocked avatars, and daily bonus status.

`player_identities` schema:

- `id`
- `player_id`
- `provider`
- `external_id`
- `created_at`
- `UNIQUE(provider, external_id)`

This is already the correct database shape for mapping Steam identities to internal server player ids.

`db_smoke_test.ts` already includes a basic Steam identity smoke path:

- `auth_provider = "steam"`
- `external_id = "steam_76561198000000000"`
- Confirms a `player_identities` row is created.
- Confirms internal `player_id` is not equal to the Steam external id.
- Confirms invalid provider is rejected.
- Confirms empty Steam external id is rejected.

## GodotSteam Integration Point

Minimal Godot-side target:

1. Add an optional Steam wrapper, for example `scripts/services/steam_identity_provider.gd`.
2. It must not hard-require the GodotSteam plugin at parse time.
3. On startup or first identity request:
   - Check whether the Steam API singleton/class is available.
   - Initialize Steam if needed.
   - Confirm Steam is running and user is logged in.
   - Read SteamID.
   - Read persona name.
   - Optionally read avatar later; first version can use SteamID/name only.
4. Return a small identity dictionary:

```gdscript
{
  "provider": "steam",
  "external_id": steam_id,
  "display_name": persona_name,
  "avatar_id": "default"
}
```

`IdentityService.get_identity()` should then prefer this Steam identity only when the wrapper says Steam is available and valid. Otherwise it must keep the current `local_dev` behavior.

The hello payload for Steam should become:

```json
{
  "type": "hello",
  "auth_provider": "steam",
  "external_id": "<steam_id>",
  "name": "<steam persona name>",
  "player_name": "<steam persona name>",
  "avatar_id": "default"
}
```

## Fallback Strategy

Fallback must remain simple and forgiving:

- If GodotSteam is not installed, the game must still launch.
- If Steam is not running, use `local_dev`.
- If running from editor without Steam, use `local_dev`.
- Existing `--dev-player-id`, `--dev-player-name`, `--dev-save-suffix` overrides must continue to work for local two-client testing.
- Cloud server may continue accepting `local_dev` during dev/test.
- `local_dev` must be blocked or restricted only in a later production hardening phase, not in this preparation pass.

Recommended precedence:

1. Explicit dev override for local testing.
2. Valid Steam identity if Steam is available.
3. Existing local profile identity.

This avoids breaking current local_dev and public server smoke tests.

## Server-Side Strategy

Current server behavior is already compatible with basic Steam identity smoke testing:

- Accept `provider=steam`.
- Accept `external_id=steam_id`.
- Store mapping in `player_identities(provider, external_id)`.
- Use a separate internal `player_id`, not the SteamID.
- Return `server_player_id` to the client.
- Reuse the same internal player id when the same SteamID logs in again.

Important rule:

`display_name` is mutable presentation data. It can update the `players.display_name`, but it must never be used as the unique identity key.

For the first Steam smoke patch, no new server table is required because `player_identities` already supports the mapping.

## Formal Verification Later

This plan does not trust bare SteamID for formal release.

Before real Steam testing or release, the flow must add Steam auth ticket verification:

1. Client requests a Steam auth session ticket.
2. Client sends:
   - `auth_provider = "steam"`
   - `external_id = steam_id`
   - `steam_auth_ticket`
3. Server verifies the ticket with Steam Web API.
4. Server confirms the ticket belongs to the supplied SteamID.
5. Server confirms app ownership / app id.
6. Only then does server trust the Steam identity.

Until this exists, `provider=steam + external_id=steam_id` is only an early smoke-test identity path.

## Risks And Limits

- Bare `steam_id` can be spoofed by a modified client.
- Current Steam provider support is good enough for local/dev smoke tests but not secure for production.
- Server identity mapping is correct in shape, but lacks Steam ticket proof.
- GodotSteam plugin availability differs between editor/export platforms; the wrapper must avoid hard parse/runtime failures.
- Steam persona name can change and should only update display fields.
- Steam avatar fetching can be deferred; it is not required for identity correctness.

Security boundary:

This phase improves identity plumbing only. It is not an authentication solution.

## Minimal Patch Split

### Patch S1: Steam identity plan and current identity audit

- Add this plan.
- Confirm current `local_dev` and `steam` provider paths.
- Confirm `player_identities(provider, external_id)` mapping.
- No runtime code changes required.

### Patch S2: GodotSteam optional wrapper

- Add a Steam wrapper that does not require GodotSteam at parse time.
- Detect whether Steam APIs are available.
- Return unavailable cleanly if plugin/Steam is missing.
- No server changes.
- No Steam Lobby / P2P / payment.

### Patch S3: IdentityService SteamID/name with local_dev fallback

- Let `IdentityService.get_identity()` ask the optional wrapper for Steam identity.
- If valid, return `provider=steam`, `external_id=steam_id`, `display_name=persona_name`.
- Keep dev override and local_dev fallback.
- Add small client-side smoke/logging to show active provider.

### Patch S4: Server hello smoke test for provider=steam

- Extend existing smoke coverage if needed.
- Verify same Steam external id maps back to the same internal player id.
- Verify display name updates do not create a new player.
- Verify invalid provider and empty external id errors remain.

### Patch S5: Formal auth ticket verification plan

- Design Steam auth ticket payload.
- Add server-side Steam Web API verification design.
- Define failure modes and production policy.
- Do not implement until Steam app id / Web API key / deployment policy are ready.

## Explicit Non-Goals

- No Steam Lobby.
- No Steam P2P.
- No Steam payment.
- No replay changes.
- No poker rules changes.
- No wallet/economy changes.
- No server deployment changes.
- No UI redesign.
