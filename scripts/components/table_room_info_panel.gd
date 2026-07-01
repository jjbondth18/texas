extends PanelContainer
class_name TableRoomInfoPanel

var _room_label: Label
var _blinds_label: Label
var _hand_label: Label
var _progress_label: Label
var _seat_label: Label
var _timer_caption_label: Label
var _timer_bar: ProgressBar
var _timer_active := false

func _ready() -> void:
	# Sci-fi styled flat glass panel
	var style := HomeTheme.make_panel_style(
		Color(0.008, 0.006, 0.015, 0.60),
		Color(0.0, 0.75, 1.0, 0.35), # Cyan neon outline
		12,
		1
	)
	add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	_room_label = Label.new()
	_room_label.text = "Texas Hold'em"
	_room_label.add_theme_font_size_override("font_size", 18)
	_room_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_room_label)
	
	_blinds_label = Label.new()
	_blinds_label.text = "NLH 25 / 50"
	_blinds_label.add_theme_font_size_override("font_size", 13)
	_blinds_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	vbox.add_child(_blinds_label)
	
	var separator := ColorRect.new()
	separator.custom_minimum_size = Vector2(0, 1)
	separator.color = Color(1.0, 1.0, 1.0, 0.15)
	vbox.add_child(separator)
	
	_hand_label = Label.new()
	_hand_label.name = "HandIdLabel"
	_hand_label.text = "Hand #88451236"
	_hand_label.add_theme_font_size_override("font_size", 12)
	_hand_label.add_theme_color_override("font_color", Color(0.65, 0.76, 1.0, 0.7))
	vbox.add_child(_hand_label)

	_progress_label = Label.new()
	_progress_label.name = "HandProgressLabel"
	_progress_label.text = "Hand 0 / 10"
	_progress_label.add_theme_font_size_override("font_size", 12)
	_progress_label.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0, 0.82))
	vbox.add_child(_progress_label)

	_seat_label = Label.new()
	_seat_label.text = "Seat: 5"
	_seat_label.add_theme_font_size_override("font_size", 12)
	_seat_label.add_theme_color_override("font_color", Color(0.72, 0.86, 1.0, 0.78))
	vbox.add_child(_seat_label)
	
	_timer_caption_label = Label.new()
	_timer_caption_label.text = "ACTION TIMER"
	_timer_caption_label.add_theme_font_size_override("font_size", 10)
	_timer_caption_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5, 0.8)) # Pink label
	vbox.add_child(_timer_caption_label)
	
	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(0, 6)
	_timer_bar.show_percentage = false
	
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.05, 0.03, 0.08, 0.8)
	bar_bg.set_corner_radius_all(3)
	
	var bar_fg := StyleBoxFlat.new()
	bar_fg.bg_color = Color(1.0, 0.0, 0.5) # Pink progress bar
	bar_fg.set_corner_radius_all(3)
	
	_timer_bar.add_theme_stylebox_override("background", bar_bg)
	_timer_bar.add_theme_stylebox_override("fill", bar_fg)
	_timer_bar.max_value = 100
	_timer_bar.value = 0
	vbox.add_child(_timer_bar)

func _process(_delta: float) -> void:
	if not _timer_active:
		return

func set_room_info(table_id: String, blinds_text: String) -> void:
	if _hand_label:
		_hand_label.text = "Hand #%d" % int(abs(table_id.hash()) % 100000000)
	if _blinds_label:
		_blinds_label.text = "NLH %s" % blinds_text

func set_table_context(stage: String, hand_id: String, seat_id: int, blinds_text: String) -> void:
	if _room_label:
		_room_label.text = stage.to_upper()
	if _hand_label:
		_hand_label.text = "ID: %s" % hand_id
	if _blinds_label:
		_blinds_label.text = "NLH %s" % blinds_text
	set_seat(seat_id)

func set_hand_progress(progress_text: String) -> void:
	if _progress_label:
		_progress_label.text = progress_text

func set_seat(seat_id: int) -> void:
	if _seat_label:
		_seat_label.text = "Seat: %d" % seat_id

func set_action_timer(remaining_seconds: int, total_seconds: int, active: bool) -> void:
	_timer_active = active
	if _timer_caption_label:
		if active:
			_timer_caption_label.text = "ACTION TIMER  %ds" % max(remaining_seconds, 0)
		else:
			_timer_caption_label.text = "ACTION TIMER"
	if _timer_bar:
		if active:
			var total := max(total_seconds, 1)
			_timer_bar.value = clamp(float(max(remaining_seconds, 0)) / float(total) * 100.0, 0.0, 100.0)
		else:
			_timer_bar.value = 0
