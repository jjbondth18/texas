# App Routes Contract

`scripts/app/app_routes.gd` defines stable route identifiers shared by frontend and app/backend code.

## Main Navigation Routes

- `home`
- `play`
- `replay`
- `store`
- `profile`
- `settings`

`club` and generic `tournaments` are deprecated as Home Lobby main navigation items.

## PLAY Mode Routes

- `quick_play`
- `room_browser`
- `private_table`
- `training`
- `events`

## Compatibility / System Routes

- `exit`
- `table`
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
- `AppRoutes.is_system_route(route_id: String) -> bool`

Frontend buttons should emit route ids from this contract instead of inventing local strings.
