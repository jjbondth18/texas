extends Control
class_name CardView

var card_data := {"rank": "", "suit": "", "face_up": false}
var selected := false
var is_mini_back := false

var _label: Label
var _texture_rect: TextureRect
var _using_texture := false


func _ready() -> void:
	custom_minimum_size = Vector2(64, 88)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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
	_using_texture = false

	if is_mini_back:
		_label.visible = false
		_texture_rect.visible = false
		queue_redraw()
		return

	var current_height := maxf(custom_minimum_size.y, size.y)
	_label.add_theme_font_size_override("font_size", int(current_height * 0.24))

	var face_up := bool(card_data.get("face_up", false))
	var rank := _display_rank(String(card_data.get("rank", "")))
	var suit := String(card_data.get("suit", ""))
	var is_empty_slot := not face_up and rank == ""

	if is_empty_slot:
		_label.visible = false
		_texture_rect.visible = false
	elif not face_up:
		_label.visible = true
		_texture_rect.visible = false
		_label.text = "BACK"
		_label.add_theme_color_override("font_color", Color(0.7, 0.78, 1.0))
	else:
		var texture_path := _texture_path(rank, suit)
		if texture_path != "" and ResourceLoader.exists(texture_path):
			_texture_rect.texture = load(texture_path)
			_texture_rect.visible = true
			_label.visible = false
			_using_texture = true
		else:
			push_warning("Missing formal card texture for %s%s at %s" % [rank, suit, texture_path])
			_texture_rect.visible = false
			_label.visible = false
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var style_box := StyleBoxFlat.new()
	style_box.anti_aliasing = true

	if is_mini_back:
		style_box.bg_color = Color(0.04, 0.03, 0.07, 0.95)
		style_box.set_corner_radius_all(3)
		style_box.border_color = Color(0.62, 0.36, 1.0, 0.65)
		style_box.set_border_width_all(1)
		style_box.draw(get_canvas_item(), rect)
		return

	var face_up := bool(card_data.get("face_up", false))
	var rank := String(card_data.get("rank", ""))
	var is_empty_slot := not face_up and rank == ""
	style_box.set_corner_radius_all(6)

	if is_empty_slot:
		style_box.bg_color = Color(0.05, 0.05, 0.1, 0.25)
		style_box.border_color = Color(1.0, 0.0, 0.6, 0.28)
		style_box.set_border_width_all(1.5)
	elif face_up:
		if _using_texture:
			_draw_texture_card_shadow(rect)
			return
		else:
			return
	else:
		style_box.bg_color = Color(0.08, 0.09, 0.18, 0.98)
		style_box.border_color = Color(0.8, 0.88, 1.0, 0.95 if selected else 0.55)
		style_box.set_border_width_all(1.5)
	style_box.draw(get_canvas_item(), rect)


func _draw_texture_card_shadow(rect: Rect2) -> void:
	var shadow := StyleBoxFlat.new()
	shadow.anti_aliasing = true
	shadow.bg_color = Color(0.0, 0.0, 0.0, 0.24)
	shadow.set_corner_radius_all(8)
	shadow.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	shadow.shadow_size = 8
	var shadow_rect := rect.grow(-4.0)
	shadow.draw(get_canvas_item(), Rect2(shadow_rect.position + Vector2(4, 8), shadow_rect.size))


func _draw_card_shadow(rect: Rect2) -> void:
	var shadow := StyleBoxFlat.new()
	shadow.anti_aliasing = true
	shadow.bg_color = Color(0.0, 0.0, 0.0, 0.34)
	shadow.set_corner_radius_all(8)
	shadow.shadow_color = Color(0.45, 0.02, 0.45, 0.30)
	shadow.shadow_size = 14
	var shadow_rect := rect.grow(-2.0)
	shadow.draw(get_canvas_item(), Rect2(shadow_rect.position + Vector2(5, 9), shadow_rect.size))


func _draw_card_material(rect: Rect2) -> void:
	var body := rect.grow(-1.5)
	var base := StyleBoxFlat.new()
	base.anti_aliasing = true
	base.bg_color = Color(0.98, 0.98, 1.0, 0.98)
	base.border_color = Color(0.80, 0.86, 0.98, 0.70)
	base.set_border_width_all(1)
	base.set_corner_radius_all(7)
	base.draw(get_canvas_item(), body)
	for i in range(8):
		var t := float(i) / 7.0
		var stripe := Rect2(body.position + Vector2(1, body.size.y * t), Vector2(body.size.x - 2, body.size.y / 8.0 + 1.0))
		var shade := Color(0.92, 0.93, 0.98, 0.10 + t * 0.045)
		draw_rect(stripe, shade)
	draw_rect(Rect2(body.position + Vector2(3, 3), Vector2(body.size.x - 6, body.size.y * 0.28)), Color(1.0, 1.0, 1.0, 0.16))


func _draw_procedural_card(rect: Rect2) -> void:
	var rank := _display_rank(String(card_data.get("rank", "")))
	var suit := String(card_data.get("suit", ""))
	var color := _suit_color(suit)
	var font := get_theme_default_font()
	var corner_size := int(rect.size.y * 0.15)
	var rank_pos := Vector2(rect.position.x + rect.size.x * 0.11, rect.position.y + rect.size.y * 0.21)
	_draw_suit_pip(rect.get_center() + Vector2(0, rect.size.y * 0.10), rect.size.x * 0.30, suit, Color(color.r, color.g, color.b, 0.12))
	draw_string(font, rank_pos, rank, HORIZONTAL_ALIGNMENT_LEFT, -1, corner_size, color)
	_draw_suit_pip(Vector2(rect.position.x + rect.size.x * 0.25, rect.position.y + rect.size.y * 0.34), rect.size.x * 0.10, suit, color)
	_draw_suit_pip(rect.get_center() + Vector2(0, rect.size.y * 0.08), rect.size.x * 0.20, suit, color)
	draw_string(font, Vector2(rect.position.x + rect.size.x * 0.66, rect.position.y + rect.size.y * 0.88), rank, HORIZONTAL_ALIGNMENT_LEFT, -1, corner_size, color)
	_draw_suit_pip(Vector2(rect.position.x + rect.size.x * 0.76, rect.position.y + rect.size.y * 0.70), rect.size.x * 0.10, suit, color)


func _draw_suit_pip(center: Vector2, radius: float, suit: String, color: Color) -> void:
	match suit:
		"diamonds":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -radius),
				center + Vector2(radius * 0.72, 0),
				center + Vector2(0, radius),
				center + Vector2(-radius * 0.72, 0),
			]), color)
		"hearts":
			draw_circle(center + Vector2(-radius * 0.38, -radius * 0.22), radius * 0.42, color)
			draw_circle(center + Vector2(radius * 0.38, -radius * 0.22), radius * 0.42, color)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-radius * 0.82, 0),
				center + Vector2(radius * 0.82, 0),
				center + Vector2(0, radius * 0.95),
			]), color)
		"clubs":
			draw_circle(center + Vector2(0, -radius * 0.42), radius * 0.42, color)
			draw_circle(center + Vector2(-radius * 0.42, radius * 0.14), radius * 0.42, color)
			draw_circle(center + Vector2(radius * 0.42, radius * 0.14), radius * 0.42, color)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-radius * 0.18, radius * 0.20),
				center + Vector2(radius * 0.18, radius * 0.20),
				center + Vector2(radius * 0.32, radius * 0.95),
				center + Vector2(-radius * 0.32, radius * 0.95),
			]), color)
		_:
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -radius),
				center + Vector2(radius * 0.72, -radius * 0.10),
				center + Vector2(radius * 0.28, radius * 0.56),
				center + Vector2(radius * 0.18, radius),
				center + Vector2(-radius * 0.18, radius),
				center + Vector2(-radius * 0.28, radius * 0.56),
				center + Vector2(-radius * 0.72, -radius * 0.10),
			]), color)


func _texture_path(rank: String, suit: String) -> String:
	var folder := ""
	var prefix := ""
	match suit:
		"club":
			folder = "club"
			prefix = "cardClubs_"
		"clubs":
			folder = "club"
			prefix = "cardClubs_"
		"diamond":
			folder = "diamond"
			prefix = "cardDiamonds_"
		"diamonds":
			folder = "diamond"
			prefix = "cardDiamonds_"
		"heart":
			folder = "heart"
			prefix = "cardHearts_"
		"hearts":
			folder = "heart"
			prefix = "cardHearts_"
		"spade":
			folder = "spade"
			prefix = "cardSpades_"
		"spades":
			folder = "spade"
			prefix = "cardSpades_"
	if folder == "" or rank == "":
		return ""
	return "res://assets/card/%s/%s%s.png" % [folder, prefix, rank]


func _display_rank(rank: String) -> String:
	return "10" if rank == "T" else rank


func _suit_symbol(suit: String) -> String:
	match suit:
		"clubs":
			return "C"
		"diamonds":
			return "D"
		"hearts":
			return "H"
		"spades":
			return "S"
	return "?"


func _suit_color(suit: String) -> Color:
	if suit in ["hearts", "diamonds"]:
		return Color(0.86, 0.1, 0.28)
	return Color(0.05, 0.07, 0.12)
