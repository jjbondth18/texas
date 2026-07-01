extends Control
class_name ActionBar

# POKER TABLE UI FREEZE:
# Do not change layout/position/size of existing poker table UI nodes unless the task explicitly asks for visual changes.
# Logic/data binding changes are allowed, but must not move or resize frozen UI components.

signal action_pressed(action: Dictionary)

var actions: Array[Dictionary] = []
var pot_amount: int = 0

var _fold_action: Dictionary
var _check_call_action: Dictionary
var _raise_action: Dictionary
var _all_in_action: Dictionary

@onready var chips_label: Label = $IdentityZone/ChipsLabel
@onready var profit_label: Label = $IdentityZone/ProfitLabel
@onready var winrate_label: Label = $IdentityZone/WinRateLabel

@onready var timer_label: Label = $FocusZone/TurnTimer
@onready var local_cards_root: Control = $FocusZone/LocalHoleCards

@onready var _fold_button: Button = $ControlZone/MainButtons/FoldButton
@onready var _check_call_button: Button = $ControlZone/MainButtons/CheckCallButton
@onready var _raise_confirm_button: Button = $ControlZone/MainButtons/BetRaiseButton
@onready var _minus_button: Button = $ControlZone/RaiseControlPanel/MinusButton
@onready var _plus_button: Button = $ControlZone/RaiseControlPanel/PlusButton
@onready var _h_slider: HSlider = $ControlZone/RaiseControlPanel/RaiseSlider
@onready var _pot_25_button: Button = $ControlZone/RaiseControlPanel/PotMultiplierButton
@onready var _max_button: Button = $ControlZone/RaiseControlPanel/MaxButton
@onready var _raise_value_label: Label = $ControlZone/RaiseControlPanel/RaiseValueLabel
@onready var _avatar_rect: TextureRect = $IdentityZone/AvatarPanel/AvatarRect

var _player_name_label: Label
var _you_badge: PanelContainer
var _chips_caption_label: Label
var _buy_in_value_label: Label
var _buy_in_caption_label: Label
var _session_caption_label: Label
var _winrate_caption_label: Label
var _buy_in_tile: Panel
var _session_tile: Panel
var _winrate_tile: Panel
var _buy_in_icon_label: Label
var _session_icon_label: Label
var _winrate_icon_label: Label
var _hand_base: Panel
var _hand_subtitle_label: Label
var _hand_title_label: Label
var _bet_title_label: Label
var _pot_half_button: Button
var _pot_two_thirds_button: Button
var _pot_button: Button
var _all_in_button: Button
var _bold_font: SystemFont

var _glass_shader: Shader
var _avatar_shader: Shader
var _accum_time := 0.0
var _turn_timer_active := false
var _turn_timer_remaining := 0
var _turn_timer_total := 0
var _turn_timer_is_local := false


func _ready() -> void:
	_bold_font = SystemFont.new()
	_bold_font.font_names = PackedStringArray(["sans-serif", "Segoe UI", "Arial"])
	_bold_font.font_weight = 700

	_glass_shader = Shader.new()

	_glass_shader.code = _make_glass_card_shader_code()

	_avatar_shader = Shader.new()
	_avatar_shader.code = "shader_type canvas_item;\n\nuniform float time_speed = 2.0;\nuniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.55, 1.0);\nuniform float glow_intensify = 0.6;\n\nvoid fragment() {\n    vec2 uv = UV;\n    vec2 center = vec2(0.5, 0.5);\n    float dist = distance(uv, center);\n    \n    // Mask at dist = 0.41 (circle crop)\n    float mask = smoothstep(0.41, 0.40, dist);\n    \n    // Avatar texture mapping\n    vec4 tex_color = texture(TEXTURE, uv);\n    \n    // Metallic border (gold/magenta mix) at 0.40 < dist < 0.44\n    float border_mask = smoothstep(0.40, 0.41, dist) * smoothstep(0.44, 0.43, dist);\n    float angle = atan(uv.y - 0.5, uv.x - 0.5);\n    float metallic = sin(angle * 5.0 + TIME * 0.8) * 0.2 + 0.8;\n    vec4 metal_color = mix(vec4(1.0, 0.82, 0.25, 1.0), glow_color, sin(TIME * 0.5 + angle) * 0.5 + 0.5) * metallic;\n    \n    // Pulsing Outer Glow Ring at 0.43 < dist < 0.49\n    float pulse = 0.8 + sin(TIME * time_speed) * 0.2;\n    float glow_mask = smoothstep(0.42, 0.44, dist) * smoothstep(0.49, 0.45, dist) * pulse;\n    vec4 outer_glow = glow_color * 1.8 * glow_intensify;\n    \n    // Large soft radial bloom behind the badge\n    float bloom = smoothstep(0.5, 0.0, dist) * 0.22 * glow_intensify * (0.85 + sin(TIME * time_speed) * 0.15);\n    vec4 bloom_color = glow_color * bloom;\n    \n    vec4 final_color = vec4(0.0);\n    final_color = mix(final_color, bloom_color, 1.0 - mask);\n    final_color = mix(final_color, tex_color, mask);\n    final_color = mix(final_color, metal_color, border_mask);\n    final_color = mix(final_color, outer_glow, glow_mask * 0.7);\n    \n    final_color.a = max(mask, max(border_mask, max(glow_mask * 0.5, bloom * 0.8)));\n    COLOR = final_color;\n}"

	# Hide all guides inside BottomHud to keep UI extremely clean and visual-focused
	for guide_path in [
		"GuideBottomHudBorder",
		"GuideBottomHudLabel",
		"IdentityZone/GuideIdentityZoneBorder",
		"IdentityZone/GuideIdentityZoneLabel",
		"FocusZone/GuideFocusZoneBorder",
		"FocusZone/GuideFocusZoneLabel",
		"ControlZone/GuideControlZoneBorder",
		"ControlZone/GuideControlZoneLabel"
	]:
		var guide_node := get_node_or_null(guide_path)
		if guide_node != null:
			guide_node.visible = false

	_apply_glass_card_material($IdentityZone, Color(1.0, 0.10, 0.72), 0.95, 0.05)
	_apply_glass_card_material($FocusZone, Color(0.72, 0.28, 1.0), 1.16, 0.32)
	_apply_glass_card_material($ControlZone, Color(0.08, 0.72, 1.0), 1.02, 0.61)
	_configure_card_depth($IdentityZone)
	_configure_card_depth($FocusZone)
	_configure_card_depth($ControlZone)
	for zone in [$IdentityZone, $FocusZone, $ControlZone]:
		zone.visible = true
		zone.mouse_entered.connect(_on_glass_card_hover_entered.bind(zone))
		zone.mouse_exited.connect(_on_glass_card_hover_exited.bind(zone))

	_build_player_info_overlay()
	$IdentityZone.mouse_filter = Control.MOUSE_FILTER_PASS
	$IdentityZone.mouse_entered.connect(_on_profile_hover_entered)
	$IdentityZone.mouse_exited.connect(_on_profile_hover_exited)
	_build_hand_panel()
	_build_action_controls()
	_style_raise_value_label()
	_layout_player_info_panel()
	_layout_hand_panel()
	_layout_action_panel()

	_style_action_button(_fold_button, Color(0.45, 0.45, 0.52), 0)
	_style_action_button(_check_call_button, Color(1.0, 0.0, 0.5), 1)
	_style_action_button(_raise_confirm_button, Color(0.0, 0.75, 1.0), 2)
	_style_adjust_button(_minus_button)
	_style_adjust_button(_plus_button)
	_style_h_slider(_h_slider)
	for btn in [_pot_half_button, _pot_two_thirds_button, _pot_button, _all_in_button]:
		_style_quick_button(btn)

	_fold_button.pressed.connect(func(): action_pressed.emit(_fold_action.duplicate(true)))
	_check_call_button.pressed.connect(func(): action_pressed.emit(_check_call_action.duplicate(true)))
	_raise_confirm_button.pressed.connect(_on_raise_confirm_pressed)
	_h_slider.value_changed.connect(_on_slider_value_changed)

	_minus_button.pressed.connect(func():
		var step := int(max(10, (_h_slider.max_value - _h_slider.min_value) / 50))
		_h_slider.value = clamp(_h_slider.value - step, _h_slider.min_value, _h_slider.max_value)
	)
	_plus_button.pressed.connect(func():
		var step := int(max(10, (_h_slider.max_value - _h_slider.min_value) / 50))
		_h_slider.value = clamp(_h_slider.value + step, _h_slider.min_value, _h_slider.max_value)
	)
	_pot_half_button.pressed.connect(func(): _set_raise_fraction(0.5))
	_pot_two_thirds_button.pressed.connect(func(): _set_raise_fraction(0.67))
	_pot_button.pressed.connect(func(): _set_raise_fraction(1.0))
	_all_in_button.pressed.connect(_on_all_in_pressed)


func set_local_player_info(local: Dictionary, phase: String = "preflop") -> void:
	if local.is_empty():
		return
	var is_server_authoritative := bool(local.get("server_authoritative", false))
	var chips := int(local.get("chips", 24500))
	var buy_in := int(local.get("buy_in", 20000))
	if buy_in <= 0:
		buy_in = 0 if is_server_authoritative else 20000
	var profit := chips - buy_in
	var win_rate := String(local.get("win_rate", "N/A" if is_server_authoritative else _phase_win_rate(phase)))

	_player_name_label.text = String(local.get("player_name", "Luna0581"))
	_you_badge.visible = bool(local.get("is_local", true))
	var avatar_texture: Texture2D = local.get("avatar_texture", null) as Texture2D
	var avatar_panel: Control = $IdentityZone/AvatarPanel
	var initials_label: Label = avatar_panel.get_node_or_null("AvatarInitials") as Label
	if initials_label != null:
		var display_name: String = String(local.get("player_name", ""))
		initials_label.text = display_name.substr(0, 1).to_upper() if display_name != "" else "?"
	if avatar_texture != null:
		_avatar_rect.texture = avatar_texture
		if initials_label != null:
			initials_label.visible = false
	elif initials_label != null:
		initials_label.visible = true
	chips_label.text = _format_chips(chips)
	_buy_in_value_label.text = _format_chips(buy_in)
	profit_label.text = ("%+d" % profit) if abs(profit) < 1000 else ("%+s" % _format_chips(profit))
	profit_label.add_theme_color_override("font_color", Color(0.0, 0.95, 0.55) if profit >= 0 else Color(1.0, 0.18, 0.24))
	_apply_info_tile_style(_session_tile, Color(0.0, 0.95, 0.55, 0.70) if profit >= 0 else Color(1.0, 0.18, 0.24, 0.70))
	winrate_label.text = win_rate


func set_actions(new_actions: Array, current_pot: int = 0) -> void:
	actions = []
	for action in new_actions:
		actions.append(Dictionary(action).duplicate(true))
	pot_amount = current_pot

	_fold_action = {}
	_check_call_action = {}
	_raise_action = {}
	_all_in_action = {}

	for action in actions:
		var action_id := String(action.get("id", ""))
		if action_id == "fold":
			_fold_action = action
		elif action_id == "check":
			if _check_call_action.is_empty():
				_check_call_action = action
		elif action_id == "call":
			if bool(action.get("enabled", false)) or _check_call_action.is_empty():
				_check_call_action = action
		elif action_id in ["bet", "raise"]:
			_raise_action = action
		elif action_id == "all_in":
			_all_in_action = action

	if not _fold_action.is_empty():
		_fold_button.disabled = not bool(_fold_action.get("enabled", true))
		_fold_button.text = String(_fold_action.get("label", "FOLD")).to_upper()
	else:
		_fold_button.disabled = true
		_fold_button.text = "FOLD"

	if not _check_call_action.is_empty():
		_check_call_button.disabled = not bool(_check_call_action.get("enabled", true))
		var amt := int(_check_call_action.get("amount", 0))
		_check_call_button.text = "CALL %d" % amt if amt > 0 else "CHECK"
	else:
		_check_call_button.disabled = true
		_check_call_button.text = "CHECK"

	if not _raise_action.is_empty():
		var enabled := bool(_raise_action.get("enabled", true))
		_raise_confirm_button.disabled = not enabled
		_minus_button.disabled = not enabled
		_plus_button.disabled = not enabled
		_h_slider.editable = enabled
		for btn in [_pot_half_button, _pot_two_thirds_button, _pot_button, _all_in_button]:
			btn.disabled = not enabled

		var min_amt := int(_raise_action.get("min_amount", 100))
		var max_amt := int(_raise_action.get("max_amount", 5000))
		_h_slider.min_value = min_amt
		_h_slider.max_value = max_amt
		_h_slider.value = min_amt
		_raise_confirm_button.text = String(_raise_action.get("id", "raise")).to_upper()
		_raise_value_label.text = _format_chips(min_amt)
	else:
		_raise_confirm_button.disabled = true
		_minus_button.disabled = true
		_plus_button.disabled = true
		_h_slider.editable = false
		for btn in [_pot_half_button, _pot_two_thirds_button, _pot_button, _all_in_button]:
			btn.disabled = true
		_raise_confirm_button.text = "RAISE"
		_raise_value_label.text = "0"

	if not _all_in_action.is_empty():
		_all_in_button.disabled = not bool(_all_in_action.get("enabled", true))


func set_turn_prompt(prompt: String) -> void:
	if _bet_title_label == null:
		return
	_bet_title_label.text = prompt.to_upper()


func set_action_timer(remaining_seconds: int, total_seconds: int, active: bool, is_local_turn: bool) -> void:
	_turn_timer_active = active
	_turn_timer_remaining = max(remaining_seconds, 0)
	_turn_timer_total = max(total_seconds, 1)
	_turn_timer_is_local = is_local_turn
	if timer_label == null:
		return
	timer_label.visible = active
	if not active:
		timer_label.text = ""
		return
	var label: String = "YOUR TURN" if is_local_turn else "TURN TIMER"
	timer_label.text = "%s  %ds" % [label, _turn_timer_remaining]
	var ratio: float = clamp(float(_turn_timer_remaining) / float(_turn_timer_total), 0.0, 1.0)
	var color: Color = Color(1.0, 0.32, 0.80) if ratio <= 0.35 else Color(0.84, 0.87, 1.0)
	timer_label.add_theme_color_override("font_color", color)


func _build_player_info_overlay() -> void:
	_player_name_label = _make_label("Luna0581", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, true)
	$IdentityZone.add_child(_player_name_label)

	_you_badge = PanelContainer.new()
	_you_badge.name = "YouBadge"
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(1.0, 0.0, 0.5, 0.95)
	badge_style.set_corner_radius_all(5)
	badge_style.content_margin_left = 7
	badge_style.content_margin_right = 7
	badge_style.content_margin_top = 2
	badge_style.content_margin_bottom = 3
	_you_badge.add_theme_stylebox_override("panel", badge_style)
	var badge_label := _make_label("YOU", 11, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, true)
	_you_badge.add_child(badge_label)
	$IdentityZone.add_child(_you_badge)
	var initials := _make_label("L", 46, Color(0.90, 0.88, 1.0, 0.96), HORIZONTAL_ALIGNMENT_CENTER, true)
	initials.name = "AvatarInitials"
	initials.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$IdentityZone/AvatarPanel.add_child(initials)

	_chips_caption_label = _make_label("CHIPS", 12, Color(0.65, 0.55, 0.80), HORIZONTAL_ALIGNMENT_LEFT, false)
	_buy_in_value_label = _make_label("20,000", 19, Color(0.93, 0.93, 1.0), HORIZONTAL_ALIGNMENT_LEFT, false)
	_buy_in_caption_label = _make_label("BUY-IN", 12, Color(0.65, 0.55, 0.80), HORIZONTAL_ALIGNMENT_LEFT, false)
	_session_caption_label = _make_label("SESSION RESULT", 12, Color(0.65, 0.55, 0.80), HORIZONTAL_ALIGNMENT_LEFT, false)
	_winrate_caption_label = _make_label("WIN RATE", 12, Color(0.65, 0.55, 0.80), HORIZONTAL_ALIGNMENT_LEFT, false)
	_buy_in_tile = _make_info_tile("BuyInTile", Color(0.78, 0.45, 1.0, 0.55))
	_session_tile = _make_info_tile("SessionTile", Color(0.0, 0.95, 0.55, 0.55))
	_winrate_tile = _make_info_tile("WinrateTile", Color(1.0, 0.0, 0.5, 0.50))
	for node in [_buy_in_tile, _session_tile, _winrate_tile]:
		$IdentityZone.add_child(node)
	_buy_in_icon_label = _make_label("$", 18, Color(1.0, 0.82, 0.25), HORIZONTAL_ALIGNMENT_CENTER, true)
	_session_icon_label = _make_label("+", 18, Color(0.0, 0.95, 0.55), HORIZONTAL_ALIGNMENT_CENTER, true)
	_winrate_icon_label = _make_label("%", 18, Color(0.74, 0.62, 1.0), HORIZONTAL_ALIGNMENT_CENTER, true)
	for node in [_buy_in_icon_label, _session_icon_label, _winrate_icon_label]:
		$IdentityZone.add_child(node)
	for node in [_chips_caption_label, _buy_in_value_label, _buy_in_caption_label, _session_caption_label, _winrate_caption_label]:
		$IdentityZone.add_child(node)

	chips_label.add_theme_font_override("font", _bold_font)
	chips_label.add_theme_font_size_override("font_size", 42)
	chips_label.add_theme_color_override("font_color", Color(1.0, 0.75, 1.0))
	chips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	profit_label.add_theme_font_override("font", _bold_font)
	profit_label.add_theme_font_size_override("font_size", 23)
	winrate_label.add_theme_font_override("font", _bold_font)
	winrate_label.add_theme_font_size_override("font_size", 19)
	winrate_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5))

func _build_hand_panel() -> void:
	_hand_base = Panel.new()
	_hand_base.name = "HandGlowBase"
	_hand_base.add_theme_stylebox_override("panel", _make_hand_base_style())
	$FocusZone.add_child(_hand_base)
	_hand_title_label = _make_label("YOUR HAND", 14, Color(0.84, 0.87, 1.0), HORIZONTAL_ALIGNMENT_CENTER, true)
	$FocusZone.add_child(_hand_title_label)
	_hand_subtitle_label = _make_label("HIGH CARD: ACE", 12, Color(0.86, 0.80, 1.0, 0.90), HORIZONTAL_ALIGNMENT_CENTER, false)
	$FocusZone.add_child(_hand_subtitle_label)
	timer_label.text = "YOUR HAND"
	timer_label.add_theme_font_override("font", _bold_font)
	timer_label.add_theme_font_size_override("font_size", 14)
	timer_label.add_theme_color_override("font_color", Color(0.84, 0.87, 1.0))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.visible = false


func _build_action_controls() -> void:
	_bet_title_label = _make_label("BET AMOUNT", 13, Color(0.84, 0.87, 1.0), HORIZONTAL_ALIGNMENT_CENTER, true)
	$ControlZone.add_child(_bet_title_label)

	_pot_half_button = _pot_25_button
	_pot_two_thirds_button = _make_button("2/3 POT")
	_pot_button = _make_button("POT")
	_all_in_button = _max_button
	_pot_half_button.text = "1/2 POT"
	_all_in_button.text = "ALL-IN"
	$ControlZone/RaiseControlPanel.add_child(_pot_two_thirds_button)
	$ControlZone/RaiseControlPanel.add_child(_pot_button)


func _style_raise_value_label() -> void:
	_raise_value_label.add_theme_font_override("font", _bold_font)
	_raise_value_label.add_theme_font_size_override("font_size", 23)
	_raise_value_label.add_theme_color_override("font_color", Color(0.64, 0.92, 1.0))
	_raise_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_raise_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _layout_player_info_panel() -> void:
	var panel := $IdentityZone
	panel.position = Vector2(0, 0)
	panel.size = Vector2(785, 368)
	panel.custom_minimum_size = panel.size
	_configure_card_depth(panel)
	var avatar_panel := $IdentityZone/AvatarPanel
	avatar_panel.position = Vector2(24, 62)
	avatar_panel.size = Vector2(188, 188)
	avatar_panel.custom_minimum_size = avatar_panel.size
	
	# Disable clip_children so the shader outer glow ring can draw outside the cropped avatar area
	avatar_panel.clip_children = Control.CLIP_CHILDREN_DISABLED
	avatar_panel.pivot_offset = avatar_panel.size * 0.5
	
	var empty_style := StyleBoxEmpty.new()
	avatar_panel.add_theme_stylebox_override("panel", empty_style)
	
	_avatar_rect.size = Vector2(176, 176)
	_avatar_rect.position = (avatar_panel.size - _avatar_rect.size) * 0.5
	_avatar_rect.custom_minimum_size = _avatar_rect.size
	_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_avatar_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_avatar_rect.material = null
	_avatar_rect.modulate = Color.WHITE
	_avatar_rect.self_modulate = Color.WHITE

	var avatar_path := "res://assets/ChatGPT Image 2026楠?閺?4閺?22_13_25 (5).png"
	if ResourceLoader.exists(avatar_path):
		_avatar_rect.texture = load(avatar_path)
		var initials := avatar_panel.get_node_or_null("AvatarInitials") as Label
		if initials != null:
			initials.visible = false

	_player_name_label.position = Vector2(220, 68)
	_player_name_label.size = Vector2(170, 32)
	_you_badge.position = Vector2(390, 74)
	_you_badge.size = Vector2(50, 24)

	_chips_caption_label.position = Vector2(220, 112)
	_chips_caption_label.size = Vector2(120, 24)
	chips_label.position = Vector2(220, 132)
	chips_label.size = Vector2(280, 52)
	
	_buy_in_value_label.position = Vector2(520, 126)
	_buy_in_value_label.size = Vector2(170, 28)
	_buy_in_caption_label.position = Vector2(520, 103)
	_buy_in_caption_label.size = Vector2(120, 22)

	var old_divider := panel.get_node_or_null("InfoDivider")
	if old_divider != null:
		old_divider.queue_free()

	_buy_in_tile.position = Vector2(220, 236)
	_buy_in_tile.size = Vector2(142, 78)
	_session_tile.position = Vector2(382, 236)
	_session_tile.size = Vector2(160, 78)
	_winrate_tile.position = Vector2(562, 236)
	_winrate_tile.size = Vector2(150, 78)
	_buy_in_icon_label.position = Vector2(235, 272)
	_buy_in_icon_label.size = Vector2(24, 24)
	_session_icon_label.position = Vector2(397, 272)
	_session_icon_label.size = Vector2(24, 24)
	_winrate_icon_label.position = Vector2(577, 272)
	_winrate_icon_label.size = Vector2(24, 24)
	_buy_in_caption_label.position = Vector2(238, 248)
	_buy_in_caption_label.size = Vector2(110, 20)
	_buy_in_value_label.position = Vector2(270, 276)
	_buy_in_value_label.size = Vector2(82, 28)
	profit_label.position = Vector2(430, 276)
	profit_label.size = Vector2(92, 28)
	_session_caption_label.position = Vector2(400, 248)
	_session_caption_label.size = Vector2(130, 20)
	_winrate_caption_label.position = Vector2(580, 248)
	_winrate_caption_label.size = Vector2(100, 20)
	winrate_label.position = Vector2(610, 276)
	winrate_label.size = Vector2(78, 28)


func _layout_hand_panel() -> void:
	var panel := $FocusZone
	panel.position = Vector2(801, 0)
	panel.size = Vector2(332, 368)
	panel.custom_minimum_size = panel.size
	_configure_card_depth(panel)
	_hand_title_label.position = Vector2(0, 36)
	_hand_title_label.size = Vector2(332, 24)
	_hand_base.position = Vector2(38, 82)
	_hand_base.size = Vector2(256, 188)
	_hand_subtitle_label.position = Vector2(72, 282)
	_hand_subtitle_label.size = Vector2(176, 26)
	timer_label.position = Vector2(0, 58)
	timer_label.size = Vector2(332, 20)
	local_cards_root.position = Vector2(42, 88)
	local_cards_root.size = Vector2(250, 190)
	for i in range(local_cards_root.get_child_count()):
		var card := local_cards_root.get_child(i) as Control
		if card == null:
			continue
		card.position = Vector2(20 + i * 106, 18 - i * 3)
		card.size = Vector2(112, 168)
		card.custom_minimum_size = card.size
		card.pivot_offset = card.size * 0.5
		card.rotation_degrees = -5.0 if i == 0 else 5.0


func _layout_action_panel() -> void:
	var panel := $ControlZone
	panel.position = Vector2(1139, 0)
	panel.size = Vector2(656, 368)
	panel.custom_minimum_size = panel.size
	_configure_card_depth(panel)
	_bet_title_label.position = Vector2(0, 28)
	_bet_title_label.size = Vector2(656, 18)
	_raise_value_label.position = Vector2(202, -48)
	_raise_value_label.size = Vector2(180, 34)

	var controls := $ControlZone/RaiseControlPanel
	controls.position = Vector2(36, 92)
	controls.size = Vector2(584, 146)
	_minus_button.position = Vector2(0, 4)
	_minus_button.size = Vector2(46, 46)
	_plus_button.position = Vector2(538, 4)
	_plus_button.size = Vector2(46, 46)
	_h_slider.position = Vector2(76, 15)
	_h_slider.size = Vector2(432, 26)

	_pot_half_button.position = Vector2(0, 76)
	_pot_two_thirds_button.position = Vector2(146, 76)
	_pot_button.position = Vector2(292, 76)
	_all_in_button.position = Vector2(438, 76)
	for btn in [_pot_half_button, _pot_two_thirds_button, _pot_button, _all_in_button]:
		btn.size = Vector2(118, 44)
		btn.custom_minimum_size = btn.size

	var main_buttons := $ControlZone/MainButtons
	main_buttons.position = Vector2(36, 254)
	main_buttons.size = Vector2(584, 82)
	_fold_button.position = Vector2(0, 0)
	_check_call_button.position = Vector2(196, 0)
	_raise_confirm_button.position = Vector2(388, 0)
	_fold_button.size = Vector2(172, 72)
	_check_call_button.size = Vector2(172, 72)
	_raise_confirm_button.size = Vector2(196, 76)
	for btn in [_fold_button, _check_call_button, _raise_confirm_button]:
		btn.custom_minimum_size = btn.size


func _make_glass_card_shader_code() -> String:
	return """shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.045, 0.018, 0.080, 0.82);
uniform vec4 accent_color : source_color = vec4(1.0, 0.0, 0.55, 1.0);
uniform float card_brightness = 1.0;
uniform float flow_phase = 0.0;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.42;
uniform float refraction_strength = 0.025;
uniform float hover_refraction = 0.0;
uniform float depth_bias = 1.0;
uniform float breathing_brightness = 1.0;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float soft_noise(vec2 uv) {
	float a = rand(floor(uv * 36.0));
	float b = rand(floor(uv * 54.0) + vec2(17.0, 3.0));
	return mix(a, b, 0.35);
}

void fragment() {
	vec2 uv = UV;
	float radius = 0.055;
	vec2 rounded = max(abs(uv - vec2(0.5)) - vec2(0.5 - radius), 0.0);
	float corner_mask = 1.0 - smoothstep(radius * 0.92, radius, length(rounded));

	// Layer A: fake refraction distortion inside an individual card.
	float refract_noise = soft_noise(uv + vec2(TIME * 0.010 + flow_phase, -TIME * 0.006));
	float distortion_wave = sin((uv.x * 2.0 + uv.y * 1.15 + TIME * 0.22 + flow_phase) * 6.28318) * 0.5 + 0.5;
	vec2 refracted_uv = uv + vec2(refract_noise - 0.5, 0.5 - refract_noise) * (refraction_strength + hover_refraction * 0.028);
	refracted_uv += vec2(distortion_wave - 0.5, 0.0) * (0.008 + hover_refraction * 0.010);

	// Layer B: internal thickness gradient.
	float lower_lift = smoothstep(0.08, 1.0, refracted_uv.y);
	float center_light = 1.0 - smoothstep(0.08, 0.78, distance(refracted_uv, vec2(0.50, 0.58)));
	float top_compression = 1.0 - smoothstep(0.00, 0.34, refracted_uv.y);
	float bottom_bevel = smoothstep(0.80, 1.0, uv.y);
	float upper_bevel = 1.0 - smoothstep(0.00, 0.12, uv.y);
	vec4 color = base_color;
	color.rgb *= (0.56 + lower_lift * 0.42 + center_light * 0.24) * card_brightness * depth_bias;
	color.rgb = mix(color.rgb, color.rgb * 0.58, top_compression * 0.72);

	// Layer C: inner shadow and fog volume around each card.
	float vignette = uv.x * (1.0 - uv.x) * uv.y * (1.0 - uv.y) * 16.0;
	vignette = clamp(pow(vignette, 0.18), 0.0, 1.0);
	color.rgb = mix(color.rgb * 0.30, color.rgb, vignette);
	float inner_fog = (1.0 - vignette) * 0.42 + center_light * 0.18 + lower_lift * 0.16;
	color.rgb = mix(color.rgb, vec3(0.18, 0.10, 0.28), inner_fog * 0.42);
	color.rgb *= breathing_brightness;
	color.rgb += accent_color.rgb * bottom_bevel * 0.20 * card_brightness;
	color.rgb += vec3(0.20, 0.16, 0.28) * upper_bevel * 0.08;

	// Layer D: precise thin neon rim per card.
	float dist_x = min(uv.x, 1.0 - uv.x);
	float dist_y = min(uv.y, 1.0 - uv.y);
	float min_dist = min(dist_x, dist_y);
	float rim = smoothstep(0.009, 0.0, min_dist);
	float bevel_glass = smoothstep(0.030, 0.0, min_dist);
	float rim_pulse = 0.86 + sin(TIME * 1.15) * 0.04;
	color.rgb += accent_color.rgb * rim * rim_intensity * rim_pulse;
	color.rgb += vec3(0.58, 0.45, 0.95) * bevel_glass * 0.075;
	float edge_path = fract(uv.x + uv.y * 0.18 - TIME * 0.10 + flow_phase);
	float edge_flow = (1.0 - smoothstep(0.0, 0.22, edge_path)) * bevel_glass;
	color.rgb += accent_color.rgb * edge_flow * 0.22;

	// Layer E: visible slow specular sweep.
	float sweep_axis = uv.x * 0.92 + uv.y * 0.42;
	float sweep_center = fract(TIME * 0.075 + flow_phase);
	float sweep = 1.0 - smoothstep(0.00, 0.12, abs(sweep_axis - sweep_center));
	color.rgb += mix(vec3(0.18, 0.62, 1.0), accent_color.rgb, 0.55) * sweep * 0.16;

	// Layer F: soft internal flowing light band, same rhythm across cards.
	float curved = uv.x + sin(uv.y * 3.14159) * 0.075;
	float flow = sin((curved - TIME * 0.115 + flow_phase) * 6.28318) * 0.5 + 0.5;
	flow = smoothstep(0.58, 0.96, flow);
	color.rgb += accent_color.rgb * flow * (0.12 + hover_refraction * 0.08) * vignette;

	// Micro grain and faint refracted highlights keep the card from reading flat.
	float grain = soft_noise(refracted_uv * 1.8 + vec2(TIME * 0.004, 0.0));
	float highlight = smoothstep(0.35, 1.0, sin((refracted_uv.x * 1.1 + refracted_uv.y * 0.55) * 6.28318) * 0.5 + 0.5);
	color.rgb += vec3(grain * 0.024);
	color.rgb += accent_color.rgb * highlight * 0.026 * vignette;

	color.a *= corner_mask;
	COLOR = color;
}"""


func _on_slider_value_changed(val: float) -> void:
	if not _raise_action.is_empty():
		_raise_value_label.text = _format_chips(int(val))


func _on_raise_confirm_pressed() -> void:
	if not _raise_action.is_empty():
		var action_data := _raise_action.duplicate(true)
		action_data["amount"] = int(_h_slider.value)
		action_pressed.emit(action_data)


func _on_all_in_pressed() -> void:
	if not _all_in_action.is_empty() and bool(_all_in_action.get("enabled", true)):
		action_pressed.emit(_all_in_action.duplicate(true))
		return
	_h_slider.value = _h_slider.max_value


func _set_raise_fraction(fraction: float) -> void:
	if pot_amount > 0:
		_h_slider.value = clamp(fraction * pot_amount, _h_slider.min_value, _h_slider.max_value)


func _make_label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment, bold: bool) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", _bold_font)
	return label


func _make_button(text_value: String) -> Button:
	var btn := Button.new()
	btn.text = text_value
	btn.focus_mode = Control.FOCUS_NONE
	return btn


func _make_panel_style(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.030, 0.105, 0.84)
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.22)
	style.shadow_size = 14
	return style


func _make_info_tile(name_value: String, border_color: Color) -> Panel:
	var panel := Panel.new()
	panel.name = name_value
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_info_tile_style(panel, border_color)
	return panel


func _apply_info_tile_style(panel: Panel, border_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.025, 0.11, 0.46)
	style.border_color = Color(border_color.r, border_color.g, border_color.b, 0.36)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.12)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)


func _make_avatar_badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.012, 0.045, 0.96)
	style.border_color = Color(1.0, 0.0, 0.56, 0.92)
	style.set_border_width_all(3)
	style.set_corner_radius_all(66)
	style.shadow_color = Color(1.0, 0.0, 0.62, 0.42)
	style.shadow_size = 26
	return style


func _make_hand_base_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.03, 0.13, 0.10)
	style.border_color = Color(1.0, 0.0, 0.55, 0.06)
	style.set_border_width_all(0)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 6
	return style


func _style_action_button(btn: Button, border_color: Color, level: int = 0) -> void:
	var alpha := 0.58 + level * 0.08
	var bg_color := Color(0.026, 0.018, 0.060, alpha)
	if level == 1:
		bg_color = Color(0.30, 0.025, 0.155, 0.82)
	elif level == 2:
		bg_color = Color(0.025, 0.29, 0.46, 0.90)

	var style_normal := HomeTheme.make_button_style(bg_color, border_color * 0.82, 14)
	style_normal.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.18 + level * 0.12)
	style_normal.shadow_size = 10 + level * 3
	style_normal.shadow_offset = Vector2(0, 4)
	var style_hover := HomeTheme.make_button_style(bg_color + Color(0.05, 0.045, 0.065, 0.12), border_color, 14)
	style_hover.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.48 + level * 0.12)
	style_hover.shadow_size = 15 + level * 5
	style_hover.shadow_offset = Vector2(0, 4)
	var style_pressed := HomeTheme.make_button_style(bg_color.darkened(0.08), border_color, 14)
	style_pressed.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.34 + level * 0.10)
	style_pressed.shadow_size = 8 + level * 3
	var style_disabled := HomeTheme.make_button_style(Color(0.008, 0.006, 0.015, 0.20), Color(border_color.r, border_color.g, border_color.b, 0.20), 14)

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.48, 0.55, 0.35))
	btn.add_theme_font_override("font", _bold_font)
	btn.add_theme_font_size_override("font_size", 17)


func _style_adjust_button(btn: Button) -> void:
	var border_color := Color(0.62, 0.55, 1.0, 0.52)
	var style_normal := HomeTheme.make_button_style(Color(0.10, 0.07, 0.20, 0.62), border_color, 20)
	var style_hover := HomeTheme.make_button_style(Color(0.14, 0.10, 0.27, 0.78), Color(0.85, 0.78, 1.0, 0.86), 20)
	var style_disabled := HomeTheme.make_button_style(Color(0.05, 0.05, 0.07, 0.2), Color(0.2, 0.2, 0.25, 0.2), 20)
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4, 0.3))
	btn.add_theme_font_override("font", _bold_font)
	btn.add_theme_font_size_override("font_size", 19)


func _style_quick_button(btn: Button) -> void:
	var border_color := Color(0.78, 0.48, 1.0, 0.45)
	var style_normal := HomeTheme.make_button_style(Color(0.08, 0.05, 0.16, 0.62), border_color, 9)
	style_normal.shadow_color = Color(0.40, 0.12, 0.80, 0.12)
	style_normal.shadow_size = 5
	var style_hover := HomeTheme.make_button_style(Color(0.13, 0.07, 0.22, 0.76), Color(1.0, 0.0, 0.5, 0.85), 9)
	style_hover.shadow_color = Color(1.0, 0.0, 0.5, 0.26)
	style_hover.shadow_size = 9
	var style_disabled := HomeTheme.make_button_style(Color(0.05, 0.05, 0.07, 0.2), Color(0.2, 0.2, 0.25, 0.2), 7)
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4, 0.3))
	btn.add_theme_font_override("font", _bold_font)
	btn.add_theme_font_size_override("font_size", 13)


func _style_h_slider(slider: HSlider) -> void:
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(0.10, 0.075, 0.18, 0.84)
	track_style.border_color = Color(0.72, 0.56, 1.0, 0.30)
	track_style.set_border_width_all(1)
	track_style.set_corner_radius_all(3)
	track_style.content_margin_top = 4
	track_style.content_margin_bottom = 4
	track_style.shadow_color = Color(0.72, 0.24, 1.0, 0.26)
	track_style.shadow_size = 10
	slider.add_theme_stylebox_override("slider", track_style)

	var active_style := StyleBoxFlat.new()
	active_style.bg_color = Color(1.0, 0.0, 0.58)
	active_style.set_corner_radius_all(3)
	active_style.content_margin_top = 4
	active_style.content_margin_bottom = 4
	active_style.shadow_color = Color(1.0, 0.0, 0.58, 0.42)
	active_style.shadow_size = 12
	slider.add_theme_stylebox_override("grabber_area", active_style)
	slider.add_theme_stylebox_override("grabber_area_highlight", active_style)

	var image := Image.create(18, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(18):
		for x in range(18):
			var dist := Vector2(x - 8.5, y - 8.5).length()
			if dist <= 7.5:
				image.set_pixel(x, y, Color(0.78, 0.72, 1.0))
			elif dist <= 8.5:
				image.set_pixel(x, y, Color(1.0, 0.0, 0.5, 0.55))
	var texture := ImageTexture.create_from_image(image)
	slider.add_theme_icon_override("grabber", texture)
	slider.add_theme_icon_override("grabber_highlight", texture)


func _phase_win_rate(phase: String) -> String:
	match phase.to_lower():
		"flop":
			return "72.8%"
		"turn":
			return "85.5%"
		"river":
			return "94.1%"
		"showdown":
			return "100.0%"
	return "54.2%"


func _format_chips(value: int) -> String:
	var sign := "-" if value < 0 else ""
	var s := str(abs(value))
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return sign + result


func _apply_glass_card_material(panel: Panel, accent_color: Color, brightness: float, phase: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = Color(1, 1, 1, 0)
	style.set_border_width_all(0)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.16)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	panel.add_theme_stylebox_override("panel", style)
	panel.clip_children = Control.CLIP_CHILDREN_DISABLED
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var mat := ShaderMaterial.new()
	mat.shader = _glass_shader
	mat.set_shader_parameter("base_color", Color(0.045, 0.018, 0.080, 0.82))
	mat.set_shader_parameter("accent_color", accent_color)
	mat.set_shader_parameter("card_brightness", brightness)
	mat.set_shader_parameter("flow_phase", phase)
	mat.set_shader_parameter("depth_bias", 1.0)
	mat.set_shader_parameter("hover_refraction", 0.0)
	panel.material = mat
	panel.set_meta("glass_base_brightness", brightness)
	panel.set_meta("glass_hover_brightness", brightness + 0.10)


func _configure_card_depth(panel: Control) -> void:
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2.ONE
	panel.z_index = 0
	panel.visible = true


func _on_glass_card_hover_entered(panel: Control) -> void:
	var mat := panel.material as ShaderMaterial
	if mat == null:
		return
	var base := float(panel.get_meta("glass_base_brightness", 1.0))
	var hover := float(panel.get_meta("glass_hover_brightness", base + 0.10))
	var tween := create_tween().set_parallel(true)
	tween.tween_method(func(val): mat.set_shader_parameter("hover_refraction", val), 0.0, 1.0, 0.18)
	tween.tween_method(func(val): mat.set_shader_parameter("card_brightness", val), base, hover, 0.18)
	tween.tween_method(func(val): mat.set_shader_parameter("rim_intensity", val), 0.42, 0.56, 0.18)


func _on_glass_card_hover_exited(panel: Control) -> void:
	var mat := panel.material as ShaderMaterial
	if mat == null:
		return
	var base := float(panel.get_meta("glass_base_brightness", 1.0))
	var current_brightness := base
	var tween := create_tween().set_parallel(true)
	tween.tween_method(func(val): mat.set_shader_parameter("hover_refraction", val), 1.0, 0.0, 0.22)
	tween.tween_method(func(val): mat.set_shader_parameter("card_brightness", val), current_brightness + 0.10, base, 0.22)
	tween.tween_method(func(val): mat.set_shader_parameter("rim_intensity", val), 0.56, 0.42, 0.22)


func _on_profile_hover_entered() -> void:
	var tween := create_tween().set_parallel(true)
	var avatar_panel := $IdentityZone/AvatarPanel
	tween.tween_property(avatar_panel, "scale", Vector2(1.03, 1.03), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var mat = _avatar_rect.material as ShaderMaterial
	if mat != null:
		tween.tween_method(func(val): mat.set_shader_parameter("glow_intensify", val), 0.6, 1.2, 0.25)


func _on_profile_hover_exited() -> void:
	var tween := create_tween().set_parallel(true)
	var avatar_panel := $IdentityZone/AvatarPanel
	tween.tween_property(avatar_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var mat = _avatar_rect.material as ShaderMaterial
	if mat != null:
		tween.tween_method(func(val): mat.set_shader_parameter("glow_intensify", val), 1.2, 0.6, 0.25)


func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	_accum_time += delta
	
	# 1. Slow brightness lift for the highest-priority chip count.
	chips_label.modulate = Color(1.0, 1.0, 1.0, 0.96 + sin(_accum_time * 2.2) * 0.035)
	
	# 2. Slow glass-card breathing on each floating card.
	var breathing = 0.94 + sin(_accum_time * 1.7) * 0.06
	for panel in [$IdentityZone, $FocusZone, $ControlZone]:
		var mat = panel.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("breathing_brightness", breathing)
