# Internal Beta Regression Matrix

Audit date: 2026-07-14

This matrix distinguishes source/automated verification from verification of the current Windows package. `PASS` means the available evidence covers the stated behavior. It does not imply that every surrounding UI path has been manually exercised.

## Status Legend

- `PASS`: verified by current source inspection, an automated server test, or an explicitly recorded manual test.
- `FAIL`: reproduced defect with a known failure point.
- `NOT TESTED`: no reliable current-build evidence.
- `BLOCKED`: cannot pass until a prerequisite defect or deployment mismatch is fixed.
- `MANUAL TEST REQUIRED`: automated coverage exists or source is present, but the exported Windows flow still needs a GUI test.

## Export Resource Audit

The Windows preset uses `export_filter="all_resources"`. Runtime-discovered resources still require special attention because the code uses string paths or directory enumeration.

| Resource group | Load mechanism | Current audit | Status |
| --- | --- | --- | --- |
| Character avatars (`assets/playersAv_cut`) | `DirAccess` catalog plus string-built `load()` paths | 94 PNGs exist. The directory was absent from the explicit include filter. Exported resource remapping can prevent the catalog from seeing filenames ending in `.png`. Added a directory include filter. | MANUAL TEST REQUIRED |
| Dealers (`assets/croupier/processed`) | `DirAccess` catalog and string paths | Explicitly included. Library also has a fixed-ID fallback. | PASS |
| Table backgrounds | String path and scene/resource references | Explicitly included; marker present in the current PCK. | PASS |
| Cards | Runtime suit/rank string path | Explicitly included recursively. | MANUAL TEST REQUIRED |
| Cardbacks | Runtime string paths | Explicitly included recursively. | PASS |
| Replay thumbnails | Dealer artwork selected by `dealer_id` | Covered by dealer directory; missing dealer has a fallback. | MANUAL TEST REQUIRED |
| Store product images | Current Store uses generated/mock controls rather than a production product-image catalog | No missing product-image resource was identified. Store is not production-ready. | NOT TESTED |
| Profile assets | Character avatars and shared UI textures | Avatar catalog fix requires a new export. | BLOCKED |
| Daily Bonus assets | Generated labels/cards; no dedicated image catalog | No string-loaded image dependency identified. | MANUAL TEST REQUIRED |
| Home logo/background/mode cards | Constants/string paths, with resource references elsewhere | Markers are present in the current PCK. | PASS |
| Audio | String constants loaded by `ResourceLoader` | Music/SFX markers are present in the current PCK. Runtime playback remains manual. | MANUAL TEST REQUIRED |
| Localization | `FileAccess` reads `localization/<locale>.json` | Locale JSON marker is present in the current PCK. All 12 language switches still require package-level sampling. | MANUAL TEST REQUIRED |
| Fonts | Godot/system fallback; no bundled CJK font | Expected fallback behavior, but CJK rendering is platform-dependent. | MANUAL TEST REQUIRED |

Packaging hygiene: the audited PCK contained markers for `tests/`, `docs/`, and documentation screenshots. The preset now excludes `build`, `docs`, `server`, `tests`, top-level `dev`, database files, and `.env` files. A fresh GUI export must confirm those markers are gone. Godot application scripts remain normal packaged game code; server TypeScript, databases, secrets, and development documentation must not be shipped.

## Replay Compatibility Audit

### Reproduced old replay

- Replay: `room_1_hand_000001`
- Type: old official encrypted metadata; `replay_type` predates the explicit field and currently infers `official_human`
- Storage: `official_encrypted`
- Envelope: `AES-256-CBC-HMAC-SHA256`, key version 1
- Local files: `metadata.json`, `public_preview.json`, `private.enc`, and `unlock.json` all exist
- `private.enc` file SHA-256 matches the current `metadata.json` checksum
- `unlock.json` is marked `authority=server`, but its checksum does not match the current metadata/blob
- The cached key validates neither the current separated-key HMAC nor the legacy same-key HMAC
- Client log failure: `Replay decrypt failed: HMAC mismatch`

### Root cause

Server room IDs restart at `room_1`, and replay IDs are derived from `room_id + hand_id`. After a server restart, a later hand reused `room_1_hand_000001`. The client overwrote that local replay directory with the newer blob while retaining the older `unlock.json`. On the server, replay index/key writes use `INSERT OR IGNORE`, so a duplicate replay ID can continue referring to the older key and entitlement. This is an identity collision, not an AES-GCM/CBC migration failure.

The UI displayed `UNLOCKED` because `has_unlock_cache()` previously accepted any non-empty cached replay key. The local profile's legacy `unlocked_replay_ids` is empty for the reproduced account, so it did not cause this instance.

The client now requires an official cache checksum and key version to match the current metadata before showing it as unlocked. This prevents false `UNLOCKED` and prevents attempting the known-bad key. It does not delete files, charge Gems, or invent an entitlement.

### Compatibility policy

- New official replay: server entitlement and server key are authoritative.
- Existing official replay with matching blob, checksum, key version, participant ACL, and server entitlement: playable without a second charge.
- Local cache with a mismatched checksum/key: not playable and must not display `UNLOCKED`.
- Legacy plaintext public/official development replay: classify as `Legacy Replay / Unsupported` unless migrated by a trusted tool; never upload or silently treat local unlock state as authority.
- `local_only` Training replay: stays separate from official encrypted replay.
- No replay is deleted or automatically re-unlocked during this audit.

The reproduced overwritten replay cannot be recovered from its current local files and cached key. Recovery would require the exact server key matching the current blob; the local evidence proves the cached key is not that key. The remote production database was not queried in this local audit.

## Regression Matrix

### Account / Profile

| Flow | Status | Evidence / next check |
| --- | --- | --- |
| Steam identity | PASS | Previously verified GUI/Windows smoke: Steam provider mapped to an internal player ID. Auth ticket remains a separate release requirement. |
| New player bootstrap | PASS | DB smoke covers wallet, progression, statistics, avatar unlock, and idempotent hello. |
| Nickname server rules | PASS | DB smoke covers first rename, cooldown, validation, persona separation. |
| Nickname Profile UI | MANUAL TEST REQUIRED | Current source has websocket request/response flow; exported E3.1 modal needs GUI verification. |
| Profile snapshot | PASS | Server/client tests cover authoritative priority and legacy fallback. |
| Avatar catalog display | BLOCKED | Source export filter fixed; fresh Windows GUI export must show all 94 entries. |
| Avatar select/purchase | MANUAL TEST REQUIRED | Logic/tests exist; package flow blocked until catalog appears. |
| Dealer select | MANUAL TEST REQUIRED | Dealer library and resource tests exist; exported interaction not re-run in this audit. |

### Economy

| Flow | Status | Evidence / next check |
| --- | --- | --- |
| Initial 30,000 Chips / 500 Gems | PASS | Authoritative bootstrap/db smoke and local profile defaults are covered. |
| Daily Bonus cycle and Day 7 | PASS | Server DB smoke covers authoritative claim/idempotency; GUI claim refresh needs normal beta sampling. |
| Wallet/profile sync | PASS | Profile snapshot integration tests cover authoritative replacement, not client-side addition. |
| Buy-in | PASS | DB smoke covers affordability, deduction, idempotent sit-down, and failure rollback. |
| Add Chips | PASS | Authoritative transaction/table-balance paths have smoke coverage. |
| Cash Out / waiting exit | PASS | DB smoke covers refund and duplicate protection. |
| Restart recovery | PASS | Outstanding table-balance recovery is DB-smoke covered. |
| Gem table product status | MANUAL TEST REQUIRED | Functional code exists, but product suitability for Internal Beta remains an explicit product decision. |

### Modes

| Flow | Status | Evidence / next check |
| --- | --- | --- |
| Training | MANUAL TEST REQUIRED | Local flow/tests exist; fresh exported build not exercised in this audit. |
| Quick | MANUAL TEST REQUIRED | Server smoke covers stale-room avoidance and affordability; current cloud deployment/package parity must be confirmed. |
| Browser create/join | MANUAL TEST REQUIRED | Server coverage exists for lifecycle and affordability; package flow not rerun. |
| Friends create/join | MANUAL TEST REQUIRED | Private room/code tests exist; package flow not rerun. |

### Replay

| Flow | Status | Evidence / next check |
| --- | --- | --- |
| New official replay delivery | MANUAL TEST REQUIRED | Server encrypted delivery tests pass; must create/unlock a replay with a globally unique ID after collision fix. |
| Old official replay | FAIL | Reproduced checksum/key mismatch caused by replay ID reuse and local directory overwrite. |
| AI replay | MANUAL TEST REQUIRED | Economy/type paths exist; exported authoritative unlock needs end-to-end verification. |
| Training replay | MANUAL TEST REQUIRED | Local save plus authoritative economy paths need package verification. |
| First official unlock | BLOCKED | Do not spend Gems until replay IDs are globally unique and deployment parity is confirmed. |
| Repeated playback | BLOCKED | Current old replay cannot authenticate; new replay behavior requires end-to-end test after ID fix. |
| Insufficient Gems | PASS | Server rejects without unlock/transaction in automated coverage. |

### Online Stability

| Flow | Status | Evidence / next check |
| --- | --- | --- |
| Launch timeout / stale response | PASS | Server and client static regression tests cover request IDs and cleanup. |
| Disconnect grace | PASS | DB smoke covers automatic action, retained balance, and grace state. |
| Reconnect seat reclaim | PASS | DB smoke covers same-seat recovery without second buy-in. |
| Room cleanup | PASS | DB smoke covers waiting/empty/session/private lifecycle cleanup. |
| Exit during waiting | PASS | Refund and table-balance cleanup are tested. |
| Exit/disconnect during active hand | MANUAL TEST REQUIRED | Server grace/settlement tests pass; two-client package behavior still needs sampling. |

### UI / Assets

| Flow | Status | Evidence / next check |
| --- | --- | --- |
| All avatar images | BLOCKED | Requires fresh export after include-filter fix. |
| Dealer images | PASS | Explicit include and current PCK marker confirmed. |
| Table backgrounds | PASS | Explicit include and current PCK marker confirmed. |
| Cards/cardbacks | MANUAL TEST REQUIRED | Explicit recursive include exists; all ranks/suits must be visually sampled. |
| Audio | MANUAL TEST REQUIRED | Resources are packaged; table/home BGM and core SFX need normal GUI listening. |
| Localization | MANUAL TEST REQUIRED | JSON is packaged; sample en-US, zh-CN, ja-JP, and ko-KR in export. |
| Custom modal behavior | MANUAL TEST REQUIRED | Rename/purchase/exit modals need focus, cancel, confirm, and resize checks. |

### Store / Social

| Flow | Status | Evidence / next check |
| --- | --- | --- |
| Store | BLOCKED | Current products and purchases are explicitly mock. Production must keep `ALLOW_MOCK_PURCHASES=false`; no Steam payment/receipt/refund flow exists. |
| Social page | BLOCKED | The Social panel is informational/placeholder; no friend graph or private messaging exists. |
| Friends Room | MANUAL TEST REQUIRED | This is a real private-room code flow, not a Steam friends system. |
| Room chat | MANUAL TEST REQUIRED | Table chat UI exists; moderation/persistence/abuse controls are not release-complete. |
| Achievements | NOT TESTED | Not part of this audit and must not be represented as complete. |

## Internal Beta Blockers

1. Make replay IDs globally unique across server restarts. Persist a monotonic/UUID replay ID and reject collisions instead of `INSERT OR IGNORE` silently retaining an older key.
2. Prevent client replay-directory overwrite on replay ID/checksum collision. Preserve both records or quarantine the incoming collision.
3. Add an entitlement/status read path so official replay list state comes from server authority; local `unlock.json` remains a cache only.
4. Re-export with the avatar include and development-file excludes, then verify all 94 avatars and absence of tests/docs/screenshots/server secrets in the PCK.
5. Deploy exactly the tested server commit and run one new official replay first-unlock/repeated-playback test before spending beta-user Gems.
6. Keep Store mock purchase disabled in production/Internal Beta unless the build is explicitly a developer economy sandbox.

## Minimal Fix Order

1. Replay globally unique ID plus collision-rejecting persistence.
2. Client collision quarantine and server entitlement status.
3. Fresh Windows GUI export and asset/package inspection.
4. New official replay unlock/replay-repeat regression.
5. Mode and two-client manual matrix pass.
6. Store/Social remain disabled or clearly labeled until separate product patches.
