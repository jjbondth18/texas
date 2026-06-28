# Poker Table UI Freeze

The current poker table screen is treated as the stable UI baseline.

Unless a future task explicitly asks for poker table visual changes, do not modify the layout, position, size, or styling of these areas:

- `scenes/screens/poker_table_screen.tscn` visual layout
- BottomHUD three-zone position and size
- BottomHUD `IdentityZone`, `YourHand`, and `BetAmount` areas
- `SeatPlayerCard` overall structure, size, and position
- Seat root coordinates and anchors
- Player avatar display method
- Card-back decoration position
- BetMarker position rules
- ActionToast style
- PotDisplay position
- CommunityCardsArea position
- CroupierDisplay position and size
- DealerDealOrigin position
- Right-side TableLog and Chat layout
- Left-side player list layout
- Top-right Exit, Settings, and Add Chips button layout

Logic and data-binding changes are allowed when needed for gameplay or contracts, but they must not move, resize, restyle, or rebuild the frozen UI components above.

