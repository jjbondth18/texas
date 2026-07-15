extends RefCounted
class_name MusicService

const HOME_BGM_PATH := "res://assets/music/bgm1.ogg"
const TABLE_BGM_PATH := "res://assets/music/bgm2.ogg"
const MUSIC_BUS := "Music"

static var _player: AudioStreamPlayer
static var _current_path := ""
static var _player_creation_pending := false
static var _pending_stream: AudioStream
static var _pending_path := ""
static var _pending_play_request := false
static var _missing_resource_warnings: Dictionary = {}

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
	_player_creation_pending = false
	_pending_stream = null
	_pending_path = ""
	_pending_play_request = false
	_missing_resource_warnings.clear()

static func _play_bgm(owner: Node, path: String) -> void:
	if owner == null or owner.get_tree() == null:
		return
	_ensure_music_bus()
	if _player != null and is_instance_valid(_player) and _player.is_inside_tree() and _current_path == path and _player.playing and _player.stream != null:
		return
	if _pending_play_request and _pending_path == path:
		_ensure_player(owner)
		return
	var stream: AudioStream = _load_audio_stream(path)
	if stream == null:
		_warn_missing_resource_once(path)
		return
	_set_loop_enabled(stream)
	_pending_stream = stream
	_pending_path = path
	_pending_play_request = true
	_ensure_player(owner)
	_flush_pending_play.call_deferred()

static func _ensure_player(owner: Node) -> void:
	if _player != null and is_instance_valid(_player):
		return
	if _player_creation_pending or owner == null or owner.get_tree() == null:
		return
	_player_creation_pending = true
	_create_player_deferred.call_deferred(owner.get_tree().root)

static func _create_player_deferred(root: Node) -> void:
	if _player != null and is_instance_valid(_player):
		_player_creation_pending = false
		_flush_pending_play.call_deferred()
		return
	if root == null or not is_instance_valid(root):
		_player_creation_pending = false
		return
	var player := AudioStreamPlayer.new()
	player.name = "GlobalBGMPlayer"
	player.bus = MUSIC_BUS
	player.tree_entered.connect(_on_player_tree_entered)
	player.finished.connect(_restart_current_stream)
	_player = player
	_player_creation_pending = false
	root.add_child.call_deferred(player)

static func _on_player_tree_entered() -> void:
	_flush_pending_play.call_deferred()

static func _flush_pending_play() -> void:
	if not _pending_play_request or _pending_stream == null:
		return
	if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree():
		return
	if _current_path == _pending_path and _player.stream == _pending_stream and _player.playing:
		_clear_pending_play()
		return
	_player.stream = _pending_stream
	_player.bus = MUSIC_BUS
	_current_path = _pending_path
	_clear_pending_play()
	_player.play()

static func _clear_pending_play() -> void:
	_pending_stream = null
	_pending_path = ""
	_pending_play_request = false

static func _restart_current_stream() -> void:
	if _player != null and is_instance_valid(_player) and _player.is_inside_tree() and _player.stream != null and not _player.playing:
		_player.play()

static func _load_audio_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var imported_stream := load(path) as AudioStream
		if imported_stream != null:
			return imported_stream
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return null
	return AudioStreamOggVorbis.load_from_file(absolute_path)

static func _warn_missing_resource_once(path: String) -> void:
	if _missing_resource_warnings.has(path):
		return
	_missing_resource_warnings[path] = true
	push_warning("[MusicService] Missing BGM resource: %s" % path)

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
