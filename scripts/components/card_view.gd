extends Control
class_name CardView

var card_data := {"rank": "", "suit": "", "face_up": false}
var selected := false
var _label: Label
var _texture_rect: TextureRect

var is_mini_back := false

func _ready() -> void:
	custom_minimum_size = Vector2(64, 88)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texture_rect)
	
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	add_child(_label)
	_update()

func set_as_mini_back(value: bool) -> void:
	is_mini_back = value
	if _label != null:
		_label.visible = not is_mini_back
	if is_mini_back:
		custom_minimum_size = Vector2(20, 28)
		if _texture_rect != null:
			_texture_rect.visible = false
	else:
		custom_minimum_size = Vector2(64, 88)
	_update()

func set_card(data: Dictionary) -> void:
	card_data = data.duplicate(true)
	_update()

func set_selected(value: bool) -> void:
	selected = value
	_update()

func _update() -> void:
	if _label == null or _texture_rect == null:
		return
	if is_mini_back:
		_label.visible = false
		_texture_rect.visible = false
		queue_redraw()
		return
		
	var current_height := custom_minimum_size.y
	var font_size := int(current_height * 0.24)
	_label.add_theme_font_size_override("font_size", font_size)
	var face_up := bool(card_data.get("face_up", false))
	var rank := String(card_data.get("rank", ""))
	var is_empty_slot := (not is_mini_back) and (not face_up) and (rank == "")
	
	if is_empty_slot:
		_label.visible = false
		_texture_rect.visible = false
	elif not face_up:
		_label.visible = true
		_texture_rect.visible = false
		_label.text = "◆"
		_label.add_theme_color_override("font_color", Color(0.7, 0.78, 1.0))
	else:
		_label.visible = false
		_texture_rect.visible = true
		
		var suit := String(card_data.get("suit", ""))
		if rank == "T":
			rank = "10"
		var folder := ""
		var prefix := ""
		match suit:
			"clubs":
				folder = "club"
				prefix = "cardClubs_"
			"diamonds":
				folder = "diamond"
				prefix = "cardDiamonds_"
			"hearts":
				folder = "heart"
				prefix = "cardHearts_"
			"spades":
				folder = "spade"
				prefix = "cardSpades_"
		
		if folder != "" and rank != "":
			var path := "res://assets/card/%s/%s%s.png" % [folder, prefix, rank]
			if ResourceLoader.exists(path):
				_texture_rect.texture = load(path)
			else:
				push_error("Card asset path not found: %s" % path)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if is_mini_back:
		var style_box := StyleBoxFlat.new()
		style_box.bg_color = Color(0.04, 0.03, 0.07, 0.95)
		style_box.set_corner_radius_all(3)
		style_box.border_color = Color(0.62, 0.36, 1.0, 0.65)
		style_box.set_border_width_all(1)
		style_box.anti_aliasing = true
		style_box.draw(get_canvas_item(), rect)
	else:
		var face_up := bool(card_data.get("face_up", false))
		var rank := String(card_data.get("rank", ""))
		var is_empty_slot := (not face_up) and (rank == "")
		
		var style_box := StyleBoxFlat.new()
		style_box.set_corner_radius_all(6)
		style_box.anti_aliasing = true
		
		if is_empty_slot:
			style_box.bg_color = Color(0.05, 0.05, 0.1, 0.25)
			style_box.border_color = Color(1.0, 0.0, 0.6, 0.28)
			style_box.set_border_width_all(1.5)
		elif face_up:
			style_box.bg_color = Color(0, 0, 0, 0)
			style_box.border_color = Color(0.8, 0.88, 1.0, 0.55 if not selected else 0.95)
			style_box.set_border_width_all(1.5)
		else:
			style_box.bg_color = Color(0.08, 0.09, 0.18, 0.98)
			style_box.border_color = Color(0.8, 0.88, 1.0, 0.55 if not selected else 0.95)
			style_box.set_border_width_all(1.5)
			
		style_box.draw(get_canvas_item(), rect)

func _suit_symbol(suit: String) -> String:
	match suit:
		"clubs":
			return "♣"
		"diamonds":
			return "♦"
		"hearts":
			return "♥"
		"spades":
			return "♠"
		_:
			return "?"

func _suit_color(suit: String) -> Color:
	if suit in ["hearts", "diamonds"]:
		return Color(0.86, 0.1, 0.28)
	return Color(0.05, 0.07, 0.12)

