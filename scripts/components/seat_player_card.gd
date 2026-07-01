extends Control
class_name SeatPlayerCard

# POKER TABLE UI FREEZE:
# Do not change layout/position/size of existing poker table UI nodes unless the task explicitly asks for visual changes.
# Logic/data binding changes are allowed, but must not move or resize frozen UI components.

const GLASS_BACKGROUND := preload("res://assets/ui/neon_poker_ui_clean/glass_background.png")
const AVATAR_RING := preload("res://assets/ui/neon_poker_ui_clean/avatar_ring.png")
const CARD_BACKS_PAIR := preload("res://assets/ui/neon_poker_ui_clean/card_backs_pair.png")
const CHIP_STACK := preload("res://assets/ui/neon_poker_ui_clean/chip_stack.png")
const DEALER_BADGE := preload("res://assets/ui/neon_poker_ui_clean/dealer_badge.png")
const SMALL_BLIND_BADGE := preload("res://assets/ui/neon_poker_ui_clean/small_blind_badge.png")
const BIG_BLIND_BADGE := preload("res://assets/ui/neon_poker_ui_clean/big_blind_badge.png")
const ACTIVE_TURN_GLOW := preload("res://assets/ui/neon_poker_ui_clean/active_turn_glow.png")
const CardViewScene := preload("res://scenes/components/card_view.tscn")
const VERBOSE_BET_MARKER_LOGS := false
const TABLE_POT_CENTER_DESIGN := Vector2(1280.0, 405.0)
const SEAT_PANEL_ORIGINS_BY_SEAT := {
	1: Vector2(1580.0, 190.0),
	2: Vector2(1880.0, 300.0),
	3: Vector2(2030.0, 520.0),
	4: Vector2(1760.0, 700.0),
	5: Vector2(1180.0, 710.0),
	6: Vector2(720.0, 700.0),
	7: Vector2(410.0, 520.0),
	8: Vector2(560.0, 300.0),
	9: Vector2(900.0, 190.0),
}
const BET_MARKER_ANCHORS_BY_SEAT := {
	0: Vector2(1210.0, 590.0),
	1: Vector2(1540.0, 322.0),
	2: Vector2(1660.0, 392.0),
	3: Vector2(1650.0, 535.0),
	4: Vector2(1540.0, 610.0),
	5: Vector2(1210.0, 590.0),
	6: Vector2(890.0, 610.0),
	7: Vector2(850.0, 535.0),
	8: Vector2(900.0, 392.0),
	9: Vector2(1015.0, 322.0),
}

var _is_empty: bool = true
var _is_local_player: bool = false
var _is_active_turn: bool = false
var _current_bet: int = 0
var _seat_id: int = 0
var _visual_position: int = 0
var _avatar_texture: Texture2D
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _bet_marker_panel: PanelContainer
var _bet_marker_row: HBoxContainer
var _bet_chip_icon: TextureRect
var _revealed_cards_root: HBoxContainer

@onready var _card_back_decor: TextureRect = $CardBackDecor
@onready var _glass_background: TextureRect = $GlassBackground
@onready var _avatar_container: Control = $AvatarContainer
@onready var _avatar: TextureRect = $AvatarContainer/Avatar
@onready var _avatar_ring: TextureRect = $AvatarContainer/AvatarRing
@onready var _name_label: Label = $NameLabel
@onready var _chip_icon: TextureRect = $ChipsRow/ChipIcon
@onready var _chips_label: Label = $ChipsRow/ChipsLabel
@onready var _chips_row: HBoxContainer = $ChipsRow
@onready var _dealer_badge: TextureRect = $DealerBadge
@onready var _blind_badge: TextureRect = $BlindBadge
@onready var _active_turn_glow: TextureRect = $ActiveTurnGlow
@onready var _bet_label: Label = $BetLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(324, 194)
	_name_label.add_theme_font_size_override("font_size", 22)
	_chips_label.add_theme_font_size_override("font_size", 20)
	_bet_label.add_theme_font_size_override("font_size", 18)
	_build_revealed_cards()
	_build_bet_marker()
	_build_toast()
	_apply_static_assets()
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()


func set_card_data(data: Dictionary) -> void:
	_is_empty = bool(data.get("is_empty", false))
	_is_local_player = bool(data.get("is_local_player", false))
	_is_active_turn = bool(data.get("is_active_turn", false))
	_avatar_texture = data.get("avatar_texture", null) as Texture2D

	var player_name: String = String(data.get("player_name", "EMPTY"))
	_name_label.text = "EMPTY" if _is_empty else player_name
	_name_label.modulate = Color(0.72, 0.72, 0.82, 0.74) if _is_empty else Color.WHITE

	var chips: int = int(data.get("chips", 0))
	_chips_label.text = _format_chips(chips)
	_chips_row.visible = not _is_empty
	_chip_icon.visible = not _is_empty

	_card_back_decor.visible = not _is_empty
	_apply_revealed_cards(Array(data.get("cards", [])))
	_active_turn_glow.visible = _is_active_turn and not _is_empty
	_avatar.texture = _avatar_texture
	_avatar.visible = _avatar_texture != null and not _is_empty
	_avatar_ring.modulate = Color(1, 1, 1, 0.94) if _is_local_player else Color(1, 1, 1, 0.86)

	_dealer_badge.visible = bool(data.get("is_dealer", false)) and not _is_empty
	var is_small_blind: bool = bool(data.get("is_small_blind", false))
	var is_big_blind: bool = bool(data.get("is_big_blind", false))
	_blind_badge.visible = (is_small_blind or is_big_blind) and not _is_empty
	if is_small_blind:
		_blind_badge.texture = SMALL_BLIND_BADGE
	elif is_big_blind:
		_blind_badge.texture = BIG_BLIND_BADGE

	var current_bet: int = int(data.get("current_bet", 0))
	_current_bet = current_bet
	_seat_id = int(data.get("seat_id", 0))
	_visual_position = int(data.get("visual_position", 0))
	var show_bet_marker: bool = _current_bet > 0 and not _is_empty
	_update_bet_marker(show_bet_marker)
	_layout()
	if VERBOSE_BET_MARKER_LOGS:
		var bet_side: String = _get_bet_marker_side(_seat_id)
		var bet_offset: Vector2 = _bet_marker_offset()
		print("[BetMarker] seat_id=%d bet=%d side=%s offset=%s action=%s visible=%s text=%s" % [
			_seat_id,
			_current_bet,
			bet_side,
			str(bet_offset),
			String(data.get("last_action", "")),
			str(_bet_marker_panel != null and _bet_marker_panel.visible),
			_bet_label.text,
		])

	var alpha: float = 0.46 if _is_empty else 1.0
	_glass_background.modulate = Color(0.72, 0.74, 0.84, alpha) if _is_empty else Color.WHITE
	queue_redraw()


func _build_revealed_cards() -> void:
	_revealed_cards_root = HBoxContainer.new()
	_revealed_cards_root.name = "ShowdownRevealedCards"
	_revealed_cards_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_revealed_cards_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_revealed_cards_root.add_theme_constant_override("separation", -12)
	_revealed_cards_root.visible = false
	add_child(_revealed_cards_root)
	for _i in range(2):
		var card := CardViewScene.instantiate() as CardView
		card.custom_minimum_size = Vector2(70, 96)
		card.size = Vector2(70, 96)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_revealed_cards_root.add_child(card)


func _apply_revealed_cards(cards: Array) -> void:
	if _revealed_cards_root == null:
		return
	var face_up_cards: Array[Dictionary] = []
	for card_item in cards:
		var card: Dictionary = Dictionary(card_item)
		if bool(card.get("face_up", false)):
			face_up_cards.append(card)
	var show_revealed_cards: bool = not _is_empty and not _is_local_player and face_up_cards.size() > 0
	_revealed_cards_root.visible = show_revealed_cards
	_card_back_decor.visible = not _is_empty and not show_revealed_cards
	for i in range(_revealed_cards_root.get_child_count()):
		var card_view := _revealed_cards_root.get_child(i) as CardView
		if card_view == null:
			continue
		card_view.visible = show_revealed_cards and i < face_up_cards.size()
		if i < face_up_cards.size():
			card_view.call("set_card", face_up_cards[i])


func _apply_static_assets() -> void:
	_card_back_decor.texture = CARD_BACKS_PAIR
	_glass_background.texture = GLASS_BACKGROUND
	_avatar_ring.texture = AVATAR_RING
	_chip_icon.texture = CHIP_STACK
	_dealer_badge.texture = DEALER_BADGE
	_blind_badge.texture = SMALL_BLIND_BADGE
	_active_turn_glow.texture = ACTIVE_TURN_GLOW
	if _bet_chip_icon != null:
		_bet_chip_icon.texture = CHIP_STACK
	for node in [_card_back_decor, _glass_background, _avatar, _avatar_ring, _chip_icon, _dealer_badge, _blind_badge, _active_turn_glow]:
		var texture_rect: TextureRect = node
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar.z_index = 2
	_avatar_ring.z_index = 1
	_avatar.self_modulate = Color.WHITE
	_avatar.modulate = Color.WHITE


func _layout() -> void:
	var card_size: Vector2 = Vector2(308, 119)
	var card_pos: Vector2 = Vector2(size.x * 0.5 - card_size.x * 0.5, size.y - card_size.y - 11.0)

	_glass_background.position = card_pos
	_glass_background.size = card_size

	_card_back_decor.position = card_pos + Vector2(84, -77)
	_card_back_decor.size = Vector2(180, 119)
	if _revealed_cards_root != null:
		_revealed_cards_root.position = card_pos + Vector2(80, -76)
		_revealed_cards_root.size = Vector2(188, 116)

	_avatar_container.position = card_pos + Vector2(10, 12)
	_avatar_container.size = Vector2(95, 95)
	_avatar.position = Vector2(15, 15)
	_avatar.size = Vector2(65, 65)
	_avatar_ring.position = Vector2(0, 0)
	_avatar_ring.size = Vector2(95, 95)

	_name_label.position = card_pos + Vector2(114, 30)
	_name_label.size = Vector2(141, 31)
	_chips_row.position = card_pos + Vector2(114, 68)
	_chips_row.size = Vector2(161, 35)
	_chip_icon.custom_minimum_size = Vector2(37, 33)

	_dealer_badge.position = card_pos + Vector2(260, 10)
	_dealer_badge.size = Vector2(37, 37)
	_blind_badge.position = card_pos + Vector2(257, 61)
	_blind_badge.size = Vector2(40, 40)

	_active_turn_glow.position = card_pos + Vector2(35, 106)
	_active_turn_glow.size = Vector2(238, 37)
	if _bet_marker_panel != null:
		_bet_marker_panel.position = _bet_marker_position(card_pos)
		_bet_marker_panel.size = Vector2(142, 32)
		_bet_marker_panel.custom_minimum_size = _bet_marker_panel.size
	if _bet_chip_icon != null:
		_bet_chip_icon.custom_minimum_size = Vector2(32, 28)
	if _toast_panel != null:
		_toast_panel.position = _toast_position(card_pos)
		_toast_panel.size = Vector2(150, 34)
		_toast_panel.pivot_offset = _toast_panel.size * 0.5


func _draw() -> void:
	if _is_empty:
		var avatar_center: Vector2 = _avatar_container.position + _avatar_container.size * 0.5
		draw_circle(avatar_center, 22.0, Color(0.045, 0.045, 0.070, 0.74))
		draw_arc(avatar_center, 23.0, 0.0, TAU, 36, Color(0.42, 0.36, 0.64, 0.22), 1.0, true)
		return

	if _avatar_texture == null:
		var avatar_center: Vector2 = _avatar_container.position + _avatar_container.size * 0.5
		draw_circle(avatar_center, 23.0, Color(0.035, 0.042, 0.072, 0.96))
		draw_circle(avatar_center, 11.5, Color(0.55, 0.48, 0.84, 0.14))
		draw_arc(avatar_center + Vector2(0, 1), 9.0, PI * 1.08, PI * 1.92, 18, Color(0.92, 0.90, 1.0, 0.14), 1.0, true)

	if _is_local_player:
		var rect: Rect2 = _glass_background.get_rect()
		draw_line(rect.position + Vector2(28, rect.size.y - 4), rect.position + Vector2(rect.size.x - 28, rect.size.y - 4), Color(0.34, 0.82, 1.0, 0.24), 1.0)

func _format_chips(value: int) -> String:
	var text: String = str(value)
	var result: String = ""
	var count: int = 0
	for i in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = text[i] + result
		count += 1
	return result


func _bet_text(data: Dictionary, amount: int) -> String:
	if String(data.get("status", "")) == "all_in":
		return "ALL-IN %s" % _format_chips(amount)
	return "BET %s" % _format_chips(amount)


func _build_bet_marker() -> void:
	_bet_marker_panel = PanelContainer.new()
	_bet_marker_panel.name = "BetMarker"
	_bet_marker_panel.visible = false
	_bet_marker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bet_marker_panel.add_theme_stylebox_override("panel", _bet_marker_style())
	add_child(_bet_marker_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bet_marker_panel.add_child(margin)

	_bet_marker_row = HBoxContainer.new()
	_bet_marker_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_bet_marker_row.add_theme_constant_override("separation", 4)
	_bet_marker_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_bet_marker_row)

	_bet_chip_icon = TextureRect.new()
	_bet_chip_icon.name = "BetMarkerChipIcon"
	_bet_chip_icon.visible = false
	_bet_chip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bet_chip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bet_chip_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bet_chip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bet_marker_row.add_child(_bet_chip_icon)

	if _bet_label.get_parent() != null:
		_bet_label.get_parent().remove_child(_bet_label)
	_bet_label.name = "AmountLabel"
	_bet_label.visible = true
	_bet_label.text = ""
	_bet_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_bet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bet_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bet_marker_row.add_child(_bet_label)


func _update_bet_marker(show_marker: bool) -> void:
	if _bet_marker_panel != null:
		_bet_marker_panel.visible = show_marker
	if _bet_chip_icon != null:
		_bet_chip_icon.visible = show_marker
	if _bet_label == null:
		return
	if show_marker:
		_bet_label.visible = true
		_bet_label.text = _format_chips(_current_bet)
	else:
		_bet_label.visible = false
		_bet_label.text = ""


func _bet_marker_style() -> StyleBoxFlat:
	var marker_style := StyleBoxFlat.new()
	marker_style.anti_aliasing = true
	marker_style.bg_color = Color(0.020, 0.012, 0.034, 0.68)
	marker_style.border_color = Color(1.0, 0.76, 0.30, 0.32)
	marker_style.set_border_width_all(1)
	marker_style.set_corner_radius_all(10)
	marker_style.shadow_color = Color(1.0, 0.54, 0.10, 0.13)
	marker_style.shadow_size = 5
	return marker_style


func show_action_toast(action_label: String, amount: int = 0) -> void:
	if _toast_panel == null or _toast_label == null:
		return
	var text: String = action_label.to_upper()
	if amount > 0:
		text = "%s %s" % [text, _format_chips(amount)]
	if action_label.to_upper() == "WIN" and amount > 0:
		text = "WIN +%s" % _format_chips(amount)
	_toast_label.text = text
	var accent: Color = _action_color(action_label)
	_toast_label.add_theme_color_override("font_color", accent)
	_toast_panel.add_theme_stylebox_override("panel", _toast_style(accent))
	_toast_panel.visible = true
	_toast_panel.modulate = Color(1, 1, 1, 0)
	_toast_panel.scale = Vector2(0.92, 0.92)
	var start_pos: Vector2 = _toast_panel.position
	var drift: Vector2 = _toast_center_direction() * 7.0
	_toast_panel.position = start_pos - drift
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween().set_parallel(true)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.14)
	_toast_tween.tween_property(_toast_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_property(_toast_panel, "position", start_pos, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_toast_tween.chain().tween_interval(1.20)
	_toast_tween.chain().tween_property(_toast_panel, "modulate:a", 0.0, 0.32)
	_toast_tween.finished.connect(func() -> void:
		_toast_panel.visible = false
		_toast_panel.position = start_pos
		_toast_panel.scale = Vector2.ONE
	)


func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.name = "SeatActionToast"
	_toast_panel.visible = false
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.pivot_offset = Vector2(66, 15)
	add_child(_toast_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_child(margin)

	_toast_label = Label.new()
	_toast_label.name = "ActionLabel"
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 18)
	_toast_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	_toast_label.add_theme_constant_override("shadow_offset_x", 0)
	_toast_label.add_theme_constant_override("shadow_offset_y", 2)
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_toast_label)


func _bet_marker_position(card_pos: Vector2) -> Vector2:
	return _bet_marker_offset(card_pos)


func _bet_marker_offset(_card_pos: Vector2 = Vector2.ZERO) -> Vector2:
	if BET_MARKER_ANCHORS_BY_SEAT.has(_seat_id):
		var seat_key: int = 5 if _seat_id == 0 else _seat_id
		var seat_origin: Vector2 = SEAT_PANEL_ORIGINS_BY_SEAT.get(seat_key, SEAT_PANEL_ORIGINS_BY_SEAT[5])
		var design_anchor: Vector2 = BET_MARKER_ANCHORS_BY_SEAT[_seat_id]
		return design_anchor - seat_origin - position
	var marker_size := Vector2(142.0, 32.0)
	var card_size := Vector2(308.0, 119.0)
	var top_gap: float = 58.0
	if _seat_id == 4:
		return Vector2(18.0, -marker_size.y - top_gap)
	if _seat_id == 5:
		return Vector2(card_size.x * 0.5 - marker_size.x * 0.5, -marker_size.y - top_gap)
	if _seat_id == 6:
		return Vector2(card_size.x - marker_size.x - 18.0, -marker_size.y - top_gap)
	var side: String = _get_bet_marker_side(_seat_id)
	var y_offset: float = card_size.y * 0.5 - marker_size.y * 0.5 + 4.0
	if side == "right":
		return Vector2(card_size.x + 12.0, y_offset)
	return Vector2(-marker_size.x - 12.0, y_offset)


func _get_bet_marker_side(seat_id: int) -> String:
	if seat_id >= 5 and seat_id <= 9:
		return "right"
	return "left"


func _toast_position(card_pos: Vector2) -> Vector2:
	if _visual_position in [1, 2, 3, 9]:
		return card_pos + Vector2(58, 98)
	if _visual_position in [4, 5, 6]:
		return card_pos + Vector2(58, -36)
	if _visual_position == 7:
		return card_pos + Vector2(254, 28)
	if _visual_position == 8:
		return card_pos + Vector2(-136, 28)
	return card_pos + Vector2(58, 98)


func _toast_center_direction() -> Vector2:
	if _visual_position in [1, 2, 3, 9]:
		return Vector2.DOWN
	if _visual_position in [4, 5, 6]:
		return Vector2.UP
	if _visual_position == 7:
		return Vector2.RIGHT
	if _visual_position == 8:
		return Vector2.LEFT
	return Vector2.DOWN


func _action_color(action_label: String) -> Color:
	match action_label.to_upper():
		"CHECK":
			return Color(0.86, 0.94, 1.0)
		"CALL", "SB", "BB":
			return Color(0.25, 0.92, 1.0)
		"BET", "RAISE":
			return Color(1.0, 0.48, 0.92)
		"FOLD":
			return Color(0.60, 0.60, 0.66)
		"ALL-IN":
			return Color(1.0, 0.16, 0.42)
		"WIN":
			return Color(1.0, 0.82, 0.22)
	return Color.WHITE


func _toast_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.anti_aliasing = true
	style.bg_color = Color(0.018, 0.010, 0.036, 0.84)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.58)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.22)
	style.shadow_size = 9
	return style
