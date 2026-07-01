# Private Room Flow

Friends Room is a private chip-table flow for invited players. It is not a separate poker rules mode.

## Entry Points

- `CREATE PRIVATE ROOM` opens the same table setup style used by public tables.
- `JOIN PRIVATE ROOM` accepts a short room code shared by the creator.
- Chip tables are enabled.
- Gem Match remains visible as a future option, but it is disabled / Coming Soon.

Private setup uses:

- Buy-in: `5000`, `10000`, `20000`, `50000`
- Blinds: `25/50`, `50/100`, `100/200`
- Hand count: `5`, `10`, `20`, or Unlimited
- Action time: `60` seconds

## Server Room Contract

Creating a private room sends `create_private_table` to the authoritative server.

The server creates:

- `table_type = private_chip`
- `visibility = private`
- `is_public = false`
- `allow_quick_join = false`
- a unique short `room_code`

Private rooms do not appear in the public Browser list and are never matched by Quick Play.

## Seat And Ready Flow

Private rooms reuse the managed chip-table lifecycle:

- The creator joins the room and sits through the normal `sit_down` confirmation path.
- Auto-seat uses the objective 9-player join order: `[5, 8, 2, 6, 4, 9, 1, 7, 3]`.
- The creator is seated at seat `5`.
- The second player joining by code is seated at seat `8`.
- Players start as not ready.
- Players use `READY` / `UNREADY`.
- When at least two real seated players are ready, the normal server ready countdown and hand flow starts.

Ready does not replace `sit_down`. The client must receive `sit_down_result ok=true` or a snapshot with its own occupied seat before showing Ready controls.

## Table UI

The poker table displays the private `Room Code` in Table Info / system messages so the host can share it with friends.

Private rooms do not show the public AI Warm-up button in this first version. Warm-up remains a public waiting-room practice feature only.

## Exit And Settlement

Private chip rooms use the same wallet -> table stack -> wallet boundary as public chip tables:

- `sit_down` deducts the configured buy-in from the server wallet.
- Leaving before formal play refunds the current table stack.
- Leaving after formal play starts cashes out the remaining table stack according to the shared server exit policy.
- Training and local warm-up remain practice-only and do not affect wallet balances.
