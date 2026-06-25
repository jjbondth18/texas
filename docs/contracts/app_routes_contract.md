# App Routes Contract

`scripts/app/app_routes.gd` defines stable route identifiers shared by frontend and app/backend code.

## Main Navigation Routes

- `home`
- `play`
- `replay`
- `store`
- `profile`
- `settings`

`club` and generic `tournaments` are no longer main navigation routes. If they return, they should live under `events` or another feature-specific route.

## PLAY Mode Routes

- `quick_play`
- `room_browser`
- `private_table`
- `training`
- `events`

## Replay Routes

- `replay`
- `replay_detail`
- `replay_analysis`

## Store Routes

- `store`
- `store_chips`
- `store_replay_pro`
- `store_cosmetics`
- `store_membership`

## Profile Routes

- `profile`
- `profile_stats`
- `profile_cosmetics`
- `profile_achievements`

## Settings Routes

- `settings`
- `settings_graphics`
- `settings_audio`
- `settings_controls`
- `settings_language`
- `settings_motion`

## Table / System Routes

- `table`
- `exit`

## Deprecated Compatibility Routes

These are retained for old mock callers only and must not appear in primary Home Lobby navigation:

- `club`
- `tournaments`
- `cash_tables`
- `club_games`
- `tournament_browser`

## Helpers

- `AppRoutes.all_routes() -> Array[String]`
- `AppRoutes.is_known_route(route_id: String) -> bool`
- `AppRoutes.is_main_nav_route(route_id: String) -> bool`
- `AppRoutes.is_mode_route(route_id: String) -> bool`
- `AppRoutes.is_play_mode_route(route_id: String) -> bool`
- `AppRoutes.is_replay_route(route_id: String) -> bool`
- `AppRoutes.is_store_route(route_id: String) -> bool`
- `AppRoutes.is_profile_route(route_id: String) -> bool`
- `AppRoutes.is_settings_route(route_id: String) -> bool`
- `AppRoutes.is_system_route(route_id: String) -> bool`

Frontend buttons should emit route ids from this contract instead of inventing local strings.
