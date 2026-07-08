# Mode Economy Structure

## Training

Training is an AI practice mode.

- Uses practice chips only.
- Does not deduct account chips when the table starts.
- Does not add winnings back to account chips when the table ends.
- Does not change gems.
- Does not write ranked stats such as sessions played, hands played, hands won, total profit, best session profit, or biggest pot.
- Does not update leaderboards, achievements, missions, or ranked rewards.
- Does not grant Gem rewards.

Training table contexts must carry explicit economy flags:

- `mode = "training"`
- `table_type = "training_ai"`
- `uses_practice_chips = true`
- `affects_account_balance = false`

The table may still show the local training result for the current session, but that result is only a practice summary.

## Public Chip Table Registry

Public chip tables are the shared local/mock table directory for account-chip poker.

- Quick Chip = automatically joins a public chip table through `quick_join_public_table`.
- Table Browser = manually browses, creates, and joins public chip tables from the same registry.
- Friends Room = private room code flow; it uses `table_type = "private_chip"` or `table_type = "private_gem"` and is not listed.
- Training = AI practice mode; it uses `table_type = "training_ai"` and is not listed.
- Quick Gem = automatically joins or creates server-backed public gem tables. It is not shown in the manual Browser list.

The current registry is local/mock only. A future server implementation can replace the registry while preserving the same table concepts:

- `table_type = "public_chip"`
- `currency = "chip"`
- `table_type = "public_gem"`
- `currency = "gems"`
- joinable `status` / `hand_state = "waiting" | "open" | "idle" | "pre_hand"`
- `allow_quick_join = true`
- `buy_in`, `small_blind`, `big_blind`, `hand_count`, `max_players`, and `current_players`

Quick join uses a simple mock/server rule: prefer clean waiting/open, quick-joinable, non-full public tables matching the selected config, table type, and currency; otherwise create a new clean public table of the selected currency. Hand-over, closed, dirty, private, training, opposite-currency, and disconnected-only tables are not joinable.

## Table Launch Flow

All real table launches from the Home/Lobby UI pass through the same lightweight launch transition before the poker table scene opens.

- Quick Chip: Finding a public chip table.
- Table Browser Join: Joining a public table.
- Table Browser Create: Creating a public table.
- Friends Room Start: Creating a private room table.
- Training: Preparing an AI training table.

The transition is presentation only. It does not change public table registry selection, practice-chip isolation, account chip/gem balances, session settlement, or table context data.

Quick Gem uses the same launch flow as Quick Chip, but it checks the server/local Gem wallet and creates or matches `public_gem` tables only.

## Mode Entry Labels

- Quick Chip: auto-joins an available public chip table with account chips.
- Quick Gem: auto-joins an available public gem table with account gems.
- Table Browser: manual public chip table list for browsing, creating, and joining public tables.
- Friends Room: private room code flow for invited friends; private rooms are not public tables and may be chip or gem rooms.
- Training: AI practice mode using practice chips; results do not affect account balance or ranked stats.
- Gem Match: Quick/Friends gem mode using mock/dev gems. It is not real payment.

## Server Table Exit Settlement

Server-authoritative public tables use a wallet -> table stack -> wallet loop.

- A successful server chip-table `sit_down` deducts the table buy-in from wallet with reason `table_buy_in`.
- A successful server gem-table `sit_down` deducts the table buy-in from wallet with reason `gem_table_buy_in`.
- Leaving a chip table before the first official hand starts refunds the current table stack with reason `left_before_official_hand`.
- Leaving a gem table before the first official hand starts refunds the current table stack with reason `gem_left_before_official_hand`.
- Leaving a chip table after official play has started cashes out the current uncommitted table stack with reason `table_cash_out`.
- Leaving a gem table after official play has started cashes out the current uncommitted table stack with reason `gem_table_cash_out`.
- Leaving a chip table at session complete cashes out the final table stack with reason `session_complete_cash_out`.
- Leaving a gem table at session complete cashes out the final table stack with reason `gem_session_complete_cash_out`.
- Leaving during an active hand auto-folds the seat. Chips already committed to the pot remain in the pot; only the remaining table stack is returned.
- Training and local AI warm-up are practice-only and never write wallet transactions for their wins or losses.

See `docs/table_exit_settlement_policy.md` for the full policy.

## Quick vs Table Browser vs Friends Room

Quick Play is the fast path. It keeps lightweight stake selection while avoiding explicit manual room creation flow.

- Chip Table: treats the selected Buy-in, Blinds, and Hand Count as quick join preferences.
- Gem Match: uses gems and server/local public gem table matching.

Quick Play exposes Buy-in, Blinds, and Hand Count in the setup panel. These are not manual room creation controls. They are preferences for `quick_join_public_table(config)`:

- First, quick join looks for a non-full, quick-joinable `public_chip` or `public_gem` table exactly matching the selected buy-in, blinds, hand count, and currency.
- If a matching public table exists, Quick joins that table.
- If no matching table exists, Quick automatically creates a public table using the selected config and joins it.
- Quick Chip config uses `table_type = public_chip`, `currency = chips`, buy-ins `5000/10000/20000/50000`, and blinds `25/50`, `50/100`, or `100/200`.
- Quick Gem config uses `table_type = public_gem`, `currency = gems`, buy-ins `20/50/100/200`, and blinds `1/2`, `2/5`, or `5/10`.
- Quick prefers the matching waiting table with the most real connected seated players; ties use earliest creation time, then stable table id.
- Quick never joins `playing`, `hand_result`, `session_complete`, `hand_over`, closed, dirty, private, training, local warm-up, disconnected-only, or opposite-currency tables.

If the wallet cannot cover the selected public chip/gem table buy-in, Quick Play shows the appropriate "Not enough chips" or "Not enough gems. Visit Store to get more gems." message and does not enter a table.

Table Browser is the manual public chip table flow.

- Existing public tables can be joined directly.
- Only clean joinable public chip tables are shown.
- Joining an existing public table does not open the create setup panel.
- Creating a public table opens a `CREATE PUBLIC TABLE` setup panel first.
- Public table setup uses the same visual setup panel language as Quick Play and supports Buy-in, Blinds, and Hand Count.
- Created tables use `table_type = "public_chip"`.
- Public Gem tables are entered through Quick Gem matchmaking rather than the manual Browser create flow.
- Public chip tables and public gem tables do not cross-match.
- Quick Chip auto-join can seat players into the same public chip table registry.
- Disconnected players or bots are not counted in Browser player totals.

## Public Table AI Warm-up

Public Chip tables remain real-player public tables. When fewer than two real players are seated, a table is `waiting_for_players` and does not start a formal public hand.

- Browser Create seats the creator and leaves the table waiting by default; no AI is spawned automatically.
- The poker table can show `START AI WARM-UP` while waiting.
- AI Warm-up is a separate local practice table on the host client; the server public room remains real-player-only.
- The server can record `host_in_local_warmup=true` for browser display, but AI is never added to public seats.
- Warm-up hands use practice/warm-up chips only and do not write account chip/gem balances, ranked stats, public profit, leaderboard progress, or formal public results.
- Quick Chip can create a waiting public room; local AI Warm-up is started from the table UI while waiting.
- Warm-up AI does not count toward public `current_players`; Browser player counts are real players only.
- Real players joining while the host is in local warm-up immediately interrupt the host's warm-up and return the host to the latest public room snapshot.
- If the public room has at least two real players, it can enter ready/waiting-to-start and the host can start a formal server-authoritative public hand.

Friends Room is the private casual room flow.

- Private rooms are created with a room code and joined by that code.
- Creating a private room opens a `CREATE PRIVATE ROOM` setup panel first.
- Private room setup uses the same visual setup panel language as Quick Play and supports Starting Stack / Buy-in, Blinds, and Hand Count.
- Authoritative private rooms use `table_type = "private_chip"`, `visibility = "private"`, and `is_public = false`.
- Local mock private rooms may still use `table_type = "private_room"` as a fallback context label.
- Private rooms are not listed in the public table registry and are not selected by Quick Chip.
- Private rooms reuse the public chip table seat, Ready, hand, result, session-complete, exit, and cash-out mechanics.
- Private Gem rooms are enabled through the Friends Room setup. They use `table_type = "private_gem"` and `currency = "gems"`, generate a room code, do not appear in Browser, and are never matched by Quick.
- Private Gem buy-in, exit refund, active-hand cash out, and session-complete cash out use the gem transaction reasons listed above.

## Leave / Timeout / Sit Out Rules

These rules describe the local/mock table behavior and the target contract for the future server-authoritative table.

- If a player leaves or disconnects during a hand, chips already committed to the pot remain in the pot.
- The leaving player's current hand is folded and the player is not dealt into the next hand.
- The leaving player's uncommitted table stack is not gifted to other players.
- Public chip tables record the uncommitted stack as a pending cash out/refund for future authoritative settlement.
- Private casual rooms return the uncommitted stack to the local casual room state or simply clear the seat.
- Training discards the remaining practice stack and never writes it back to account chips or gems.
- If a player times out and checking is available, the local/mock action is auto-check.
- If a player times out and checking is not available, the local/mock action is auto-fold.
- After two consecutive timeouts, the player is marked `sit_out`.
- `sit_out` players do not post new blinds, do not receive new hole cards, and are not counted as active for the next hand.
- If active players fall below the table minimum, the table moves to `paused` or `waiting` until enough players are available.
- In the P2P/mock prototype, host leave closes the table safely and reports: "Host left. Table closed safely. Account balances were not changed."
- The host client is not trusted to finalize account settlement. In the future server version, the server maintains table state and the host has no special settlement authority.

Gem tables use the same lifecycle rules as chip tables, but their table stack maps to account Gems instead of account Chips.

## Profile Progression And Cosmetic Currency

Chips are the ordinary account currency for public/private chip table buy-ins, Add Chips table transfers, and standard cosmetic purchases such as Character Avatars.

Gems are reserved for replay unlocks and future premium features. Ordinary Character Avatars do not spend Gems.

Profile progression is deliberately lightweight:

- Daily Bonus is claimed from Home with the `CLAIM` button.
- Daily Bonus grants Chips and XP on Days 1-6.
- Day 7 grants `5,000 Chips`, `50 XP`, and `5 Gems`.
- After Day 7, the next claim loops back to Day 1.
- XP currently comes only from Daily Bonus.
- Level is calculated as `floor(total_xp / 100) + 1`.
- The highest title unlocked by the player's level is shown on the Profile page.
- Titles are cosmetic profile labels only. They are not shown at the poker table and do not affect gameplay, matchmaking, cards, betting, luck, rewards, or economy.
- Ordinary Character Avatars use Chips only and require a Confirm Purchase dialog before chips are deducted.

See `docs/profile_progression.md` for the title table and avatar purchase rules.
