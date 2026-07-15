extends RefCounted
class_name MusicService

const HOME_BGM_PATH := "res://assets/music/bgm1.ogg"
const TABLE_BGM_PATH := "res://assets/music/bgm2.ogg"
const MUSIC_BUS := "Music"

static var _player: AudioStreamPlayer
static var _current_path := ""
static var _player_attach_pending := false

static func play_home_bgm(owner: Node) -> void:
	_play_bgm(owner, HOME_BGM_PATH)

static func play_table_bgm(owner: Node) -> void:
	_play_bgm(owner, TABLE_BGM_PATH)

static func ensure_home_bgm(owner: Node) -> void:
	_play_bgm(owner, HOME_BGM_PATH)

static func current_bgm_path() -> String:
	return _current_path

static func active_player_count() -> int:
	return 1 if _player != null and is_instance_valid(_player) else 0

static func uses_music_bus() -> bool:
	return _player != null and is_instance_valid(_player) and _player.bus == MUSIC_BUS

static func reset_for_tests() -> void:
	if _player != null and is_instance_valid(_player):
		_player.queue_free()
	_player = null
	_current_path = ""
	_player_attach_pending = false

static func _play_bgm(owner: Node, path: String) -> void:
	if owner == null or owner.get_tree() == null:
		return
	_ensure_music_bus()
	_ensure_player(owner)
	if _current_path == path and _player.playing and _player.stream != null:
		return
	var stream: AudioStream = _load_audio_stream(path)
	if stream == null:
		push_warning("[MusicService] Missing BGM resource: %s" % path)
		return
	_set_loop_enabled(stream)
	_player.stream = stream
	_player.bus = MUSIC_BUS
	_current_path = path
	_play_when_ready.call_deferred(path)

static func _ensure_player(owner: Node) -> void:
	if _player != null and is_instance_valid(_player):
		if _player.get_parent() == null:
			_defer_player_attach(owner)
		return
	_player = AudioStreamPlayer.new()
	_player.name = "GlobalBGMPlayer"
	_player.bus = MUSIC_BUS
	_player.finished.connect(func() -> void:
		if _player != null and is_instance_valid(_player):
			_player.play()
	)
	_defer_player_attach(owner)

static func _defer_player_attach(owner: Node) -> void:
	if _player_attach_pending or owner == null or owner.get_tree() == null:
		return
	_player_attach_pending = true
	_attach_player.call_deferred(owner.get_tree().root)

static func _attach_player(root: Node) -> void:
	_player_attach_pending = false
	if _player == null or not is_instance_valid(_player) or root == null:
		return
	if _player.get_parent() == null:
		root.add_child(_player)

static func _play_when_ready(expected_path: String) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _current_path != expected_path:
		return
	if not _player.is_inside_tree():
		_play_when_ready.call_deferred(expected_path)
		return
	if not _player.playing:
		_player.play()

static func _load_audio_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var imported_stream := load(path) as AudioStream
		if imported_stream != null:
			return imported_stream
	var absolute_path := ProjectSettings.globalize_path(path)
	return AudioStreamOggVorbis.load_from_file(absolute_path)

static func _set_loop_enabled(stream: AudioStream) -> void:
	if stream == null:
		return
	if stream.has_method("set_loop"):
		stream.set_loop(true)
	elif "loop" in stream:
		stream.loop = true

static func _ensure_music_bus() -> void:
	if AudioServer.get_bus_index(MUSIC_BUS) >= 0:
		return
	var bus_index := AudioServer.get_bus_count()
	AudioServer.add_bus(bus_index)
	AudioServer.set_bus_name(bus_index, MUSIC_BUS)
