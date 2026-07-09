extends RefCounted
class_name SfxManager

const SFX_BUS := "SFX"

const DRAW_CARD_PATH := "res://assets/music/draw.wav"
const SHUFFLE_PATH := "res://assets/music/shuffle.wav"
const CHIP_PATH := "res://assets/music/chip.wav"
const GEM_PATH := "res://assets/music/Gem.wav"
const WIN_PATH := "res://assets/music/chip_gem_win.wav"

const SFX_PATHS := {
	"draw": DRAW_CARD_PATH,
	"shuffle": SHUFFLE_PATH,
	"chip": CHIP_PATH,
	"gem": GEM_PATH,
	"win": WIN_PATH,
}

const SFX_VOLUME_DB := {
	"draw": -7.0,
	"shuffle": -8.0,
	"chip": -5.5,
	"gem": -5.5,
	"win": -4.5,
}

static var _players: Array[AudioStreamPlayer] = []
static var _played_event_ids: Dictionary = {}
static var _last_sfx_id := ""

static func play_draw_card(owner: Node, event_id: String = "") -> bool:
	return play_sfx(owner, "draw", event_id)

static func play_shuffle(owner: Node, event_id: String = "") -> bool:
	return play_sfx(owner, "shuffle", event_id)

static func play_chip(owner: Node, event_id: String = "") -> bool:
	return play_sfx(owner, "chip", event_id)

static func play_gem(owner: Node, event_id: String = "") -> bool:
	return play_sfx(owner, "gem", event_id)

static func play_win(owner: Node, event_id: String = "") -> bool:
	return play_sfx(owner, "win", event_id)

static func play_sfx(owner: Node, sfx_id: String, event_id: String = "") -> bool:
	if event_id != "":
		var unique_key := "%s:%s" % [sfx_id, event_id]
		if _played_event_ids.has(unique_key):
			return false
		_played_event_ids[unique_key] = true
	var stream := _load_sfx_stream(sfx_id)
	if stream == null:
		return false
	var player := _available_player(owner)
	if player == null:
		return false
	player.stream = stream
	player.bus = SFX_BUS
	player.volume_db = float(SFX_VOLUME_DB.get(sfx_id, -6.0))
	player.play()
	_last_sfx_id = sfx_id
	return true

static func resource_path_for(sfx_id: String) -> String:
	return str(SFX_PATHS.get(sfx_id, ""))

static func resource_exists(sfx_id: String) -> bool:
	var path := resource_path_for(sfx_id)
	return path != "" and ResourceLoader.exists(path)

static func uses_sfx_bus() -> bool:
	_ensure_sfx_bus()
	return AudioServer.get_bus_index(SFX_BUS) >= 0

static func last_sfx_id() -> String:
	return _last_sfx_id

static func played_event_count() -> int:
	return _played_event_ids.size()

static func reset_for_tests() -> void:
	_played_event_ids.clear()
	_last_sfx_id = ""

static func _available_player(owner: Node) -> AudioStreamPlayer:
	_ensure_sfx_bus()
	for player in _players:
		if is_instance_valid(player) and not player.playing:
			return player
	var tree: SceneTree = null
	if owner != null:
		tree = owner.get_tree()
	else:
		tree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var player := AudioStreamPlayer.new()
	player.name = "GlobalSFXPlayer"
	player.bus = SFX_BUS
	tree.root.add_child(player)
	_players.append(player)
	return player

static func _load_sfx_stream(sfx_id: String) -> AudioStream:
	var path := resource_path_for(sfx_id)
	if path == "":
		return null
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	if path.ends_with(".wav"):
		return AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(path))
	return null

static func _ensure_sfx_bus() -> void:
	if AudioServer.get_bus_index(SFX_BUS) >= 0:
		return
	var bus_index := AudioServer.get_bus_count()
	AudioServer.add_bus(bus_index)
	AudioServer.set_bus_name(bus_index, SFX_BUS)
