extends RefCounted
class_name MusicService

const HOME_BGM_PATH := "res://assets/music/bgm1.ogg"
const TABLE_BGM_PATH := "res://assets/music/bgm2.ogg"
const MUSIC_BUS := "Music"

static var _player: AudioStreamPlayer
static var _current_path := ""

static func play_home_bgm(owner: Node) -> void:
	_play_bgm(owner, HOME_BGM_PATH)

static func play_table_bgm(owner: Node) -> void:
	_play_bgm(owner, TABLE_BGM_PATH)

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

static func _play_bgm(owner: Node, path: String) -> void:
	if owner == null or owner.get_tree() == null:
		return
	_ensure_music_bus()
	_ensure_player(owner)
	if _current_path == path and _player.playing:
		return
	var stream: AudioStream = _load_audio_stream(path)
	if stream == null:
		push_warning("[MusicService] Missing BGM resource: %s" % path)
		return
	_set_loop_enabled(stream)
	_player.stream = stream
	_player.bus = MUSIC_BUS
	_current_path = path
	_player.play()

static func _ensure_player(owner: Node) -> void:
	if _player != null and is_instance_valid(_player):
		if _player.get_parent() == null:
			owner.get_tree().root.add_child(_player)
		return
	_player = AudioStreamPlayer.new()
	_player.name = "GlobalBGMPlayer"
	_player.bus = MUSIC_BUS
	_player.finished.connect(func() -> void:
		if _player != null and is_instance_valid(_player):
			_player.play()
	)
	owner.get_tree().root.add_child(_player)

static func _load_audio_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
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
