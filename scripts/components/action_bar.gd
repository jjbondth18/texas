extends Control
class_name ActionBar

signal action_pressed(action: Dictionary)

var actions: Array[Dictionary] = []
var pot_amount: int = 0

var _fold_action: Dictionary
var _check_call_action: Dictionary
var _raise_action: Dictionary

@onready var chips_label: Label = $PlayerInfoPanel/ChipsLabel
@onready var profit_label: Label = $PlayerInfoPanel/ProfitLabel
@onready var winrate_label: Label = $PlayerInfoPanel/WinRateLabel

@onready var timer_label: Label = $HoleCardsPanel/TurnTimer
@onready var local_cards_root: Control = $HoleCardsPanel/LocalHoleCards

@onready var _fold_button: Button = $ActionPanel/MainButtons/FoldButton
@onready var _check_call_button: Button = $ActionPanel/MainButtons/CheckCallButton
@onready var _raise_confirm_button: Button = $ActionPanel/MainButtons/BetRaiseButton
@onready var _minus_button: Button = $ActionPanel/RaiseControlPanel/MinusButton
@onready var _plus_button: Button = $ActionPanel/RaiseControlPanel/PlusButton
@onready var _h_slider: HSlider = $ActionPanel/RaiseControlPanel/RaiseSlider
@onready var _pot_25_button: Button = $ActionPanel/RaiseControlPanel/PotMultiplierButton
@onready var _max_button: Button = $ActionPanel/RaiseControlPanel/MaxButton
@onready var _raise_value_label: Label = $ActionPanel/RaiseControlPanel/RaiseValueLabel
@onready var _avatar_rect: TextureRect = $PlayerInfoPanel/AvatarPanel/AvatarRect

var _desk_surface: Panel
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


func _ready() -> void:
	_bold_font = SystemFont.new()
	_bold_font.font_names = PackedStringArray(["sans-serif", "Segoe UI", "Arial"])
	_bold_font.font_weight = 700

	_glass_shader = Shader.new()
	_glass_shader.code = "shader_type canvas_item;\n\nuniform vec4 base_color : source_color = vec4(0.06, 0.03, 0.12, 0.88);\nuniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.55, 1.0);\nuniform float pulse_intensity : hint_range(0.0, 1.0) = 0.15;\nuniform float sweep_speed = 1.0;\nuniform float sweep_intensity = 0.08;\nuniform float noise_intensity = 0.015;\nuniform float breathing_brightness = 1.0;\nuniform float left_glow_mult = 0.9;\nuniform float center_glow_mult = 1.3;\nuniform float right_glow_mult = 0.8;\n\nfloat rand(vec2 co) {\n    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);\n}\n\nvoid fragment() {\n    vec2 uv = UV;\n    \n    // Calculate regional glow multipliers\n    float glow_mult = left_glow_mult;\n    if (uv.x > 0.4418 && uv.x <= 0.6329) {\n        float t = (uv.x - 0.4418) / (0.6329 - 0.4418);\n        glow_mult = mix(left_glow_mult, center_glow_mult, smoothstep(0.0, 1.0, t));\n    } else if (uv.x > 0.6329) {\n        float t = (uv.x - 0.6329) / (1.0 - 0.6329);\n        glow_mult = mix(center_glow_mult, right_glow_mult, smoothstep(0.0, 1.0, t));\n    } else {\n        float t = uv.x / 0.4418;\n        glow_mult = mix(left_glow_mult * 0.7, left_glow_mult, smoothstep(0.0, 1.0, t));\n    }\n    \n    // Layer 1: Base glass with diagonal gradient\n    float grad = clamp(1.0 - (uv.x + uv.y) * 0.5, 0.0, 1.0);\n    vec4 color = mix(base_color * 0.8, base_color * 1.4 + vec4(0.06, 0.04, 0.14, 0.08), grad);\n    color.rgb *= breathing_brightness;\n    \n    // Layer 2: Inner shadow / depth\n    float vignette = uv.x * (1.0 - uv.x) * uv.y * (1.0 - uv.y) * 16.0;\n    vignette = clamp(pow(vignette, 0.25), 0.0, 1.0);\n    color.rgb = mix(color.rgb * 0.35, color.rgb, vignette);\n    \n    // Layer 3: Continuous outer glow rim\n    float dist_x = min(uv.x, 1.0 - uv.x);\n    float dist_y = min(uv.y, 1.0 - uv.y);\n    float min_dist = min(dist_x, dist_y);\n    float border = smoothstep(0.008, 0.0, min_dist);\n    \n    float pulse = 1.0 + sin(TIME * 2.0) * pulse_intensity;\n    vec4 edge_glow = glow_color * border * pulse * glow_mult;\n    color = mix(color, edge_glow, border);\n    \n    // Layer 4: Continuous gradient sweep/drift\n    float sweep = sin(uv.y * 3.14159 - TIME * sweep_speed) * 0.5 + 0.5;\n    color.rgb += glow_color.rgb * sweep * sweep_intensity * vignette * glow_mult;\n    \n    // Layer 5: Vertical Dividers drawn directly inside the desk surface shader\n    float div1 = smoothstep(0.0015, 0.0, abs(uv.x - 0.4418));\n    float div2 = smoothstep(0.0015, 0.0, abs(uv.x - 0.6329));\n    float div_vignette = uv.y * (1.0 - uv.y) * 4.0;\n    float divider_mask = max(div1, div2) * div_vignette;\n    color = mix(color, vec4(0.75, 0.45, 1.0, 0.15), divider_mask);\n    \n    // Layer 6: Noise shimmer overlay\n    float noise = rand(uv + vec2(TIME * 0.02)) * noise_intensity;\n    color.rgb += vec3(noise);\n    \n    COLOR = color;\n}"

	_avatar_shader = Shader.new()
	_avatar_shader.code = "shader_type canvas_item;\n\nuniform float time_speed = 2.0;\nuniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.55, 1.0);\nuniform float glow_intensify = 0.6;\n\nvoid fragment() {\n    vec2 uv = UV;\n    vec2 center = vec2(0.5, 0.5);\n    float dist = distance(uv, center);\n    \n    // Mask at dist = 0.41 (circle crop)\n    float mask = smoothstep(0.41, 0.40, dist);\n    \n    // Avatar texture mapping\n    vec4 tex_color = texture(TEXTURE, uv);\n    \n    // Metallic border (gold/magenta mix) at 0.40 < dist < 0.44\n    float border_mask = smoothstep(0.40, 0.41, dist) * smoothstep(0.44, 0.43, dist);\n    float angle = atan(uv.y - 0.5, uv.x - 0.5);\n    float metallic = sin(angle * 5.0 + TIME * 0.8) * 0.2 + 0.8;\n    vec4 metal_color = mix(vec4(1.0, 0.82, 0.25, 1.0), glow_color, sin(TIME * 0.5 + angle) * 0.5 + 0.5) * metallic;\n    \n    // Pulsing Outer Glow Ring at 0.43 < dist < 0.49\n    float pulse = 0.8 + sin(TIME * time_speed) * 0.2;\n    float glow_mask = smoothstep(0.42, 0.44, dist) * smoothstep(0.49, 0.45, dist) * pulse;\n    vec4 outer_glow = glow_color * 1.8 * glow_intensify;\n    \n    // Large soft radial bloom behind the badge\n    float bloom = smoothstep(0.5, 0.0, dist) * 0.22 * glow_intensify * (0.85 + sin(TIME * time_speed) * 0.15);\n    vec4 bloom_color = glow_color * bloom;\n    \n    vec4 final_color = vec4(0.0);\n    final_color = mix(final_color, bloom_color, 1.0 - mask);\n    final_color = mix(final_color, tex_color, mask);\n    final_color = mix(final_color, metal_color, border_mask);\n    final_color = mix(final_color, outer_glow, glow_mask * 0.7);\n    \n    final_color.a = max(mask, max(border_mask, max(glow_mask * 0.5, bloom * 0.8)));\n    COLOR = final_color;\n}"

	# Hide all guides inside BottomHud to keep UI extremely clean and visual-focused
	for guide_path in [
		"GuideBottomHudBorder",
		"GuideBottomHudLabel",
		"PlayerInfoPanel/GuidePlayerInfoPanelBorder",
		"PlayerInfoPanel/GuidePlayerInfoPanelLabel",
		"HoleCardsPanel/GuideHoleCardsPanelBorder",
		"HoleCardsPanel/GuideHoleCardsPanelLabel",
		"ActionPanel/GuideActionPanelBorder",
		"ActionPanel/GuideActionPanelLabel"
	]:
		var guide_node := get_node_or_null(guide_path)
		if guide_node != null:
			guide_node.visible = false

	# Setup the single continuous desk surface panel spanning left-to-right (0.0 to 1795.0 px)
	_desk_surface = Panel.new()
	_desk_surface.name = "DeskSurfacePanel"
	_desk_surface.position = Vector2(0, 0)
	_desk_surface.size = Vector2(1795, 368)
	_desk_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_desk_surface)
	move_child(_desk_surface, 0)

	# Override child panels style to StyleBoxEmpty to remove separate container boxes
	var empty_style := StyleBoxEmpty.new()
	$PlayerInfoPanel.add_theme_stylebox_override("panel", empty_style)
	$HoleCardsPanel.add_theme_stylebox_override("panel", empty_style)
	$ActionPanel.add_theme_stylebox_override("panel", empty_style)

	_build_player_info_overlay()
	$PlayerInfoPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	$PlayerInfoPanel.mouse_entered.connect(_on_profile_hover_entered)
	$PlayerInfoPanel.mouse_exited.connect(_on_profile_hover_exited)
	_build_hand_panel()
	_build_action_controls()
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
	_all_in_button.pressed.connect(func(): _h_slider.value = _h_slider.max_value)


func set_local_player_info(local: Dictionary, phase: String = "preflop") -> void:
	if local.is_empty():
		return
	var chips := int(local.get("chips", 24500))
	var buy_in := int(local.get("buy_in", 20000))
	if buy_in <= 0:
		buy_in = 20000
	var profit := chips - buy_in
	var win_rate := _phase_win_rate(phase)

	_player_name_label.text = String(local.get("player_name", "Luna0581"))
	_you_badge.visible = bool(local.get("is_local", true))
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

	for action in actions:
		var action_id := String(action.get("id", ""))
		if action_id == "fold":
			_fold_action = action
		elif action_id in ["check", "call"]:
			if _check_call_action.is_empty() or action_id == "call":
				_check_call_action = action
		elif action_id in ["bet", "raise"]:
			_raise_action = action

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


func _build_player_info_overlay() -> void:
	_player_name_label = _make_label("Luna0581", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, true)
	$PlayerInfoPanel.add_child(_player_name_label)

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
	var badge_label := _make_label("YOU", 10, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, true)
	_you_badge.add_child(badge_label)
	$PlayerInfoPanel.add_child(_you_badge)
	var initials := _make_label("L", 46, Color(0.90, 0.88, 1.0, 0.96), HORIZONTAL_ALIGNMENT_CENTER, true)
	initials.name = "AvatarInitials"
	initials.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$PlayerInfoPanel/AvatarPanel.add_child(initials)

	_chips_caption_label = _make_label("CHIPS", 11, Color(0.65, 0.55, 0.80), HORIZONTAL_ALIGNMENT_LEFT, false)
	_buy_in_value_label = _make_label("20,000", 18, Color(0.93, 0.93, 1.0), HORIZONTAL_ALIGNMENT_LEFT, false)
	_buy_in_caption_label = _make_label("BUY-IN", 11, Color(0.65, 0.55, 0.80), HORIZONTAL_ALIGNMENT_LEFT, false)
	_session_caption_label = _make_label("SESSION RESULT", 11, Color(0.65, 0.55, 0.80), HORIZONTAL_ALIGNMENT_LEFT, false)
	_winrate_caption_label = _make_label("WIN RATE", 11, Color(0.65, 0.55, 0.80), HORIZONTAL_ALIGNMENT_LEFT, false)
	_buy_in_tile = _make_info_tile("BuyInTile", Color(0.78, 0.45, 1.0, 0.55))
	_session_tile = _make_info_tile("SessionTile", Color(0.0, 0.95, 0.55, 0.55))
	_winrate_tile = _make_info_tile("WinrateTile", Color(1.0, 0.0, 0.5, 0.50))
	for node in [_buy_in_tile, _session_tile, _winrate_tile]:
		$PlayerInfoPanel.add_child(node)
	_buy_in_icon_label = _make_label("$", 18, Color(1.0, 0.82, 0.25), HORIZONTAL_ALIGNMENT_CENTER, true)
	_session_icon_label = _make_label("+", 18, Color(0.0, 0.95, 0.55), HORIZONTAL_ALIGNMENT_CENTER, true)
	_winrate_icon_label = _make_label("%", 18, Color(0.74, 0.62, 1.0), HORIZONTAL_ALIGNMENT_CENTER, true)
	for node in [_buy_in_icon_label, _session_icon_label, _winrate_icon_label]:
		$PlayerInfoPanel.add_child(node)
	for node in [_chips_caption_label, _buy_in_value_label, _buy_in_caption_label, _session_caption_label, _winrate_caption_label]:
		$PlayerInfoPanel.add_child(node)

	chips_label.add_theme_font_override("font", _bold_font)
	chips_label.add_theme_font_size_override("font_size", 38)
	chips_label.add_theme_color_override("font_color", Color(1.0, 0.75, 1.0))
	chips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	profit_label.add_theme_font_override("font", _bold_font)
	profit_label.add_theme_font_size_override("font_size", 22)
	winrate_label.add_theme_font_override("font", _bold_font)
	winrate_label.add_theme_font_size_override("font_size", 18)
	winrate_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5))

	_apply_glass_shader_to_panel(_desk_surface, Color(1.0, 0.0, 0.56))


func _build_hand_panel() -> void:
	_hand_base = Panel.new()
	_hand_base.name = "HandGlowBase"
	_hand_base.add_theme_stylebox_override("panel", _make_hand_base_style())
	$HoleCardsPanel.add_child(_hand_base)
	_hand_title_label = _make_label("YOUR HAND", 13, Color(0.84, 0.87, 1.0), HORIZONTAL_ALIGNMENT_CENTER, true)
	$HoleCardsPanel.add_child(_hand_title_label)
	_hand_subtitle_label = _make_label("HIGH CARD: ACE", 11, Color(0.86, 0.80, 1.0, 0.90), HORIZONTAL_ALIGNMENT_CENTER, false)
	$HoleCardsPanel.add_child(_hand_subtitle_label)
	timer_label.text = "YOUR HAND"
	timer_label.add_theme_font_override("font", _bold_font)
	timer_label.add_theme_font_size_override("font_size", 13)
	timer_label.add_theme_color_override("font_color", Color(0.84, 0.87, 1.0))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.visible = false


func _build_action_controls() -> void:
	_bet_title_label = _make_label("BET AMOUNT", 12, Color(0.84, 0.87, 1.0), HORIZONTAL_ALIGNMENT_CENTER, true)
	$ActionPanel.add_child(_bet_title_label)

	_pot_half_button = _pot_25_button
	_pot_two_thirds_button = _make_button("2/3 POT")
	_pot_button = _make_button("POT")
	_all_in_button = _max_button
	_pot_half_button.text = "1/2 POT"
	_all_in_button.text = "ALL-IN"
	$ActionPanel/RaiseControlPanel.add_child(_pot_two_thirds_button)
	$ActionPanel/RaiseControlPanel.add_child(_pot_button)


func _layout_player_info_panel() -> void:
	var panel := $PlayerInfoPanel
	var avatar_panel := $PlayerInfoPanel/AvatarPanel
	avatar_panel.position = Vector2(44, 78)
	avatar_panel.size = Vector2(132, 132)
	avatar_panel.custom_minimum_size = avatar_panel.size
	
	# Disable clip_children so the shader outer glow ring can draw outside the cropped avatar area
	avatar_panel.clip_children = Control.CLIP_CHILDREN_DISABLED
	avatar_panel.pivot_offset = avatar_panel.size * 0.5
	
	var empty_style := StyleBoxEmpty.new()
	avatar_panel.add_theme_stylebox_override("panel", empty_style)
	
	_avatar_rect.position = Vector2.ZERO
	_avatar_rect.size = avatar_panel.size
	_avatar_rect.custom_minimum_size = avatar_panel.size
	_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	# Assign the avatar metallic frame & glow pulse shader
	var av_mat := ShaderMaterial.new()
	av_mat.shader = _avatar_shader
	av_mat.set_shader_parameter("glow_color", Color(1.0, 0.0, 0.55, 1.0))
	_avatar_rect.material = av_mat

	var avatar_path := "res://assets/ChatGPT Image 2026骞?鏈?4鏃?22_13_25 (5).png"
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

	var divider := panel.get_node_or_null("InfoDivider") as ColorRect
	if divider == null:
		divider = ColorRect.new()
		divider.name = "InfoDivider"
		divider.color = Color(0.75, 0.45, 1.0, 0.30)
		panel.add_child(divider)
	divider.position = Vector2(220, 205)
	divider.size = Vector2(510, 1)

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
	_hand_title_label.position = Vector2(0, 36)
	_hand_title_label.size = Vector2(332, 24)
	_hand_base.position = Vector2(53, 78)
	_hand_base.size = Vector2(226, 184)
	_hand_subtitle_label.position = Vector2(78, 270)
	_hand_subtitle_label.size = Vector2(176, 26)
	timer_label.position = Vector2(0, 58)
	timer_label.size = Vector2(332, 20)
	local_cards_root.position = Vector2(66, 92)
	local_cards_root.size = Vector2(210, 170)
	for i in range(local_cards_root.get_child_count()):
		var card := local_cards_root.get_child(i) as Control
		if card == null:
			continue
		card.position = Vector2(12 + i * 92, 20 - i * 2)
		card.size = Vector2(92, 138)
		card.custom_minimum_size = card.size
		card.pivot_offset = card.size * 0.5
		card.rotation_degrees = -5.0 if i == 0 else 5.0


func _layout_action_panel() -> void:
	_bet_title_label.position = Vector2(0, 34)
	_bet_title_label.size = Vector2(656, 18)
	_raise_value_label.position = Vector2(235, 54)
	_raise_value_label.size = Vector2(190, 34)

	var controls := $ActionPanel/RaiseControlPanel
	controls.position = Vector2(36, 84)
	controls.size = Vector2(584, 154)
	_minus_button.position = Vector2(0, 2)
	_minus_button.size = Vector2(44, 44)
	_plus_button.position = Vector2(540, 2)
	_plus_button.size = Vector2(44, 44)
	_h_slider.position = Vector2(78, 10)
	_h_slider.size = Vector2(430, 28)

	_pot_half_button.position = Vector2(0, 70)
	_pot_two_thirds_button.position = Vector2(145, 70)
	_pot_button.position = Vector2(290, 70)
	_all_in_button.position = Vector2(435, 70)
	for btn in [_pot_half_button, _pot_two_thirds_button, _pot_button, _all_in_button]:
		btn.size = Vector2(116, 42)
		btn.custom_minimum_size = btn.size

	var main_buttons := $ActionPanel/MainButtons
	main_buttons.position = Vector2(36, 258)
	main_buttons.size = Vector2(584, 78)
	_fold_button.position = Vector2(0, 0)
	_check_call_button.position = Vector2(200, 0)
	_raise_confirm_button.position = Vector2(400, 0)
	_fold_button.size = Vector2(162, 64)
	_check_call_button.size = Vector2(162, 64)
	_raise_confirm_button.size = Vector2(190, 68)
	for btn in [_fold_button, _check_call_button, _raise_confirm_button]:
		btn.custom_minimum_size = btn.size


func _on_slider_value_changed(val: float) -> void:
	if not _raise_action.is_empty():
		_raise_value_label.text = _format_chips(int(val))


func _on_raise_confirm_pressed() -> void:
	if not _raise_action.is_empty():
		var action_data := _raise_action.duplicate(true)
		action_data["amount"] = int(_h_slider.value)
		action_pressed.emit(action_data)


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
	style.bg_color = Color(0.04, 0.02, 0.08, 0.35)
	style.border_color = Color(border_color.r, border_color.g, border_color.b, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.shadow_color = Color(0, 0, 0, 0)
	style.shadow_size = 0
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
	style.bg_color = Color(0.12, 0.04, 0.18, 0.25)
	style.border_color = Color(1.0, 0.0, 0.55, 0.15)
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0, 0, 0, 0)
	style.shadow_size = 0
	return style


func _style_action_button(btn: Button, border_color: Color, level: int = 0) -> void:
	var alpha := 0.48 + level * 0.08
	var bg_color := Color(0.016, 0.012, 0.035, alpha)
	if level == 1:
		bg_color = Color(0.22, 0.02, 0.13, 0.72)
	elif level == 2:
		bg_color = Color(0.02, 0.25, 0.42, 0.82)

	var style_normal := HomeTheme.make_button_style(bg_color, border_color * 0.65, 12)
	style_normal.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.25 + level * 0.12)
	style_normal.shadow_size = 10 + level * 3
	var style_hover := HomeTheme.make_button_style(bg_color + Color(0.04, 0.04, 0.06, 0.12), border_color, 12)
	style_hover.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.55)
	style_hover.shadow_size = 16
	var style_disabled := HomeTheme.make_button_style(Color(0.008, 0.006, 0.015, 0.20), Color(border_color.r, border_color.g, border_color.b, 0.20), 12)

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.48, 0.55, 0.35))
	btn.add_theme_font_override("font", _bold_font)
	btn.add_theme_font_size_override("font_size", 15)


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
	btn.add_theme_font_size_override("font_size", 18)


func _style_quick_button(btn: Button) -> void:
	var border_color := Color(0.78, 0.48, 1.0, 0.45)
	var style_normal := HomeTheme.make_button_style(Color(0.08, 0.05, 0.16, 0.50), border_color, 7)
	var style_hover := HomeTheme.make_button_style(Color(0.13, 0.07, 0.22, 0.70), Color(1.0, 0.0, 0.5, 0.85), 7)
	var style_disabled := HomeTheme.make_button_style(Color(0.05, 0.05, 0.07, 0.2), Color(0.2, 0.2, 0.25, 0.2), 7)
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4, 0.3))
	btn.add_theme_font_override("font", _bold_font)
	btn.add_theme_font_size_override("font_size", 12)


func _style_h_slider(slider: HSlider) -> void:
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(0.25, 0.2, 0.35, 0.58)
	track_style.set_corner_radius_all(3)
	track_style.content_margin_top = 3
	track_style.content_margin_bottom = 3
	slider.add_theme_stylebox_override("slider", track_style)

	var active_style := StyleBoxFlat.new()
	active_style.bg_color = Color(1.0, 0.0, 0.5)
	active_style.set_corner_radius_all(3)
	active_style.content_margin_top = 3
	active_style.content_margin_bottom = 3
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


func _apply_glass_shader_to_panel(panel: Panel, border_color: Color) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = _glass_shader
	mat.set_shader_parameter("base_color", Color(0.06, 0.03, 0.12, 0.88))
	mat.set_shader_parameter("glow_color", border_color)
	panel.material = mat


func _on_profile_hover_entered() -> void:
	var tween := create_tween().set_parallel(true)
	var avatar_panel := $PlayerInfoPanel/AvatarPanel
	tween.tween_property(avatar_panel, "scale", Vector2(1.06, 1.06), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var mat = _avatar_rect.material as ShaderMaterial
	if mat != null:
		tween.tween_method(func(val): mat.set_shader_parameter("glow_intensify", val), 0.6, 1.2, 0.25)
		
	var ds_mat = _desk_surface.material as ShaderMaterial
	if ds_mat != null:
		tween.tween_method(func(val): ds_mat.set_shader_parameter("left_glow_mult", val), 0.9, 1.25, 0.25)


func _on_profile_hover_exited() -> void:
	var tween := create_tween().set_parallel(true)
	var avatar_panel := $PlayerInfoPanel/AvatarPanel
	tween.tween_property(avatar_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var mat = _avatar_rect.material as ShaderMaterial
	if mat != null:
		tween.tween_method(func(val): mat.set_shader_parameter("glow_intensify", val), 1.2, 0.6, 0.25)
		
	var ds_mat = _desk_surface.material as ShaderMaterial
	if ds_mat != null:
		tween.tween_method(func(val): ds_mat.set_shader_parameter("left_glow_mult", val), 1.25, 0.9, 0.25)


func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	_accum_time += delta
	
	# 1. Subtle chips glow flicker (very subtle)
	chips_label.modulate = Color(1.0, 1.0, 1.0, 0.95 + sin(_accum_time * 16.0) * randf_range(0.015, 0.03))
	
	# 2. Active panel breathing brightness on the desk surface shader material
	if _desk_surface != null:
		var ds_mat = _desk_surface.material as ShaderMaterial
		if ds_mat != null:
			var breathing = 0.88 + sin(_accum_time * 2.5) * 0.12
			ds_mat.set_shader_parameter("breathing_brightness", breathing)
