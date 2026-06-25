# Home Lobby Frontend Rebuild Documentation

This document describes the frontend architecture, scene structure, layout alignment, state machine, and hover animations of the Texas Hold'em Home Lobby screen.

## 1. Scene Tree Structure
The reconstructed scene tree for `HomeLobbyScreen` is organized as follows:
```text
HomeLobbyScreen (Control, PRESET_FULL_RECT)
├── BackgroundRoot (Control, PRESET_FULL_RECT, mouse_filter=IGNORE)
│   ├── BackgroundTexture (TextureRect, PRESET_FULL_RECT, mouse_filter=IGNORE)
│   └── BackgroundCenterLift (ColorRect, PRESET_FULL_RECT, mouse_filter=IGNORE)
│
├── LobbyUIRoot (Control, PRESET_FULL_RECT, mouse_filter=IGNORE)
│   ├── TopBar (TopBar, mouse_filter=STOP)
│   ├── LeftNavRail (LeftNavRail, mouse_filter=IGNORE)
│   │   ├── GradientBackground (TextureRect, mouse_filter=IGNORE)
│   │   ├── BorderRight (ColorRect, mouse_filter=IGNORE)
│   │   └── NavList (VBoxContainer, mouse_filter=IGNORE)
│   │       ├── SpacerTop (Control, mouse_filter=IGNORE)
│   │       ├── NavItems... (NavItem, mouse_filter=STOP)
│   │       ├── PlaySubmenu (VBoxContainer, mouse_filter=IGNORE)
│   │       ├── SpacerFill (Control, mouse_filter=IGNORE)
│   │       └── VersionLabel (Label, mouse_filter=IGNORE)
│   ├── CenterBrand (Control, mouse_filter=IGNORE)
│   │   └── LogoTextFallback (Control, mouse_filter=IGNORE)
│   ├── PlayExpandedGroup (PanelContainer, visible=false, mouse_filter=IGNORE, custom_minimum_size.y=580)
│   │   └── ContentColumn (VBoxContainer, mouse_filter=IGNORE, custom_minimum_size.x=1320, size_flags_horizontal=SIZE_SHRINK_CENTER)
│   │       ├── ChooseRoomTitle (Label, mouse_filter=IGNORE)
│   │       ├── ModeCardRow (HBoxContainer, mouse_filter=IGNORE, separation=30)
│   │       │   └── ModeCards... (ModeCard, custom_minimum_size=240x360)
│   │       └── DailyBonusBar (PanelContainer, mouse_filter=IGNORE)
│   └── CollapsedPrompt (Label, mouse_filter=IGNORE)
```

## 2. State Machine
We use an explicit state machine for managing transition animations and component visibility:
- **States:**
  - `LobbyState.COLLAPSED`: Default lobby page. CenterBrand is fully visible (`modulate.a = 1.0`), and `PlayExpandedGroup` is hidden.
  - `LobbyState.PLAY_EXPANDED`: Entered upon clicking the `PLAY` button. CenterBrand fades to `0.15` opacity to act as a background element. `PlayExpandedGroup` fades in smoothly.
- **Method:** Transitions are centralized in `set_state(new_state: LobbyState, animated: bool)` in `home_lobby_screen.gd`.

## 3. Mouse Input Filtering (mouse_filter Rules)
To prevent click blocking by transparent container overlays:
- Non-interactive containers (`BackgroundRoot`, `LobbyUIRoot`, `PlayExpandedGroup`, `ContentColumn`, `ModeCardRow`, `SpacerTop`, `SpacerFill`, version labels, decoration texture sheets) are configured with `mouse_filter = Control.MOUSE_FILTER_IGNORE`.
- Interactive components (`NavItem` buttons, `ModeCard` cards, TopBar icons/menus) are configured with `mouse_filter = Control.MOUSE_FILTER_STOP` or `Control.MOUSE_FILTER_PASS` to consume input.

## 4. ModeCard Hover Isolation Architecture
To eliminate card jitter and shifting on adjacent cards when hovered:
- The parent container (`ModeCard` root) maintains a static `custom_minimum_size` of `Vector2(240, 360)`. It is laid out statically by `ModeCardRow`.
- All visual components (panels, textures, text labels) are placed inside a child `HoverWrapper` node (Control), which is scaled to `1.025` on hover.
- Sibling cards remain 100% stationary because the parent `ModeCard` bounding box is unchanged.
- On hover, the stylebox border color transitions to `HomeTheme.PINK` (Magenta) and shadow size is increased to `14` to render a neon border glow.

## 5. Disabled Motion Effects
All distracting dynamic visual effects have been disabled to prioritize static quality:
- No background texture scale pulse or horizontal shaking.
- No rotating background circles or diamond outline meshes.
- No panel fly-in or sliding transitions from off-screen.
- Only smooth alpha fades (logo and panel modulate transitions) and isolated card scale and border glow transitions are enabled.

## 6. Screenshots
Captured runtime verification screenshots are stored at:
- Collapsed Home: `docs/screenshots/runtime_collapsed_home.png`
- Expanded Play: `docs/screenshots/runtime_play_expanded.png`
- Hover Card Preview: `docs/screenshots/runtime_play_expanded_hover.png`

## 7. Known Limitations & Next Steps
- **ViewModel Binding:** The UI currently binds mock data from `MockHomeData`. Once Codex establishes the application view model contract, the lobby screen will bind to it directly.
