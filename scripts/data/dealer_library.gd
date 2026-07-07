extends RefCounted
class_name DealerLibrary

const CROUPIER_DIR := "res://assets/croupier/processed"
const DEFAULT_DEALER_ID := "dealer_01_dog"
const LEGACY_DEFAULT_ID := "default"

const DISPLAY_NAMES := {
	"dealer_01_dog": "Dog",
	"dealer_02_bear": "Bear",
	"dealer_03_cat": "Cat",
	"dealer_04_red_panda": "Red Panda",
	"dealer_05_armor": "Armor",
	"dealer_06_sloth": "Sloth",
	"dealer_07_statue": "Statue",
	"dealer_08_horse": "Horse",
	"dealer_09_owl": "Owl",
	"dealer_10_frog": "Frog",
	"dealer_11_walrus": "Walrus",
}

static func list_dealers() -> Array:
	var dealers := []
	var filenames := _dealer_png_filenames()
	for filename_item in filenames:
		var filename: String = String(filename_item)
		var dealer_id: String = filename.get_basename()
		dealers.append({
			"id": dealer_id,
			"display_name": display_name(dealer_id),
			"texture_path": "%s/%s" % [CROUPIER_DIR, filename],
		})
	return dealers


static func dealer_ids() -> Array:
	var ids := []
	for dealer in list_dealers():
		ids.append(String(Dictionary(dealer).get("id", "")))
	return ids


static func get_all_dealer_ids() -> Array:
	return dealer_ids()


static func get_default_dealer_id() -> String:
	return DEFAULT_DEALER_ID


static func get_dealer_texture_path(dealer_id: String) -> String:
	return texture_path(dealer_id)


static func get_random_dealer_id(seed: Variant = null) -> String:
	var ids: Array = dealer_ids()
	if ids.is_empty():
		return DEFAULT_DEALER_ID
	var rng := RandomNumberGenerator.new()
	if seed == null:
		rng.randomize()
	else:
		rng.seed = hash(str(seed))
	return str(ids[rng.randi_range(0, ids.size() - 1)])


static func normalize_dealer_id(dealer_id: String) -> String:
	var normalized: String = dealer_id.strip_edges()
	if normalized == "" or normalized == LEGACY_DEFAULT_ID:
		return DEFAULT_DEALER_ID
	return normalized if has_dealer_id(normalized) else DEFAULT_DEALER_ID


static func has_dealer_id(dealer_id: String) -> bool:
	return dealer_ids().has(dealer_id)


static func get_dealer(dealer_id: String) -> Dictionary:
	var normalized: String = normalize_dealer_id(dealer_id)
	for dealer in list_dealers():
		if String(Dictionary(dealer).get("id", "")) == normalized:
			return Dictionary(dealer)
	return {
		"id": DEFAULT_DEALER_ID,
		"display_name": display_name(DEFAULT_DEALER_ID),
		"texture_path": "%s/%s.png" % [CROUPIER_DIR, DEFAULT_DEALER_ID],
	}


static func display_name(dealer_id: String) -> String:
	var normalized: String = dealer_id if dealer_id != LEGACY_DEFAULT_ID else DEFAULT_DEALER_ID
	if DISPLAY_NAMES.has(normalized):
		return String(DISPLAY_NAMES[normalized])
	var words := normalized.replace("dealer_", "").split("_")
	var readable := []
	for word in words:
		if String(word).is_valid_int():
			continue
		readable.append(String(word).capitalize())
	return " ".join(readable) if not readable.is_empty() else "Dealer"


static func texture_path(dealer_id: String) -> String:
	return String(get_dealer(dealer_id).get("texture_path", "%s/%s.png" % [CROUPIER_DIR, DEFAULT_DEALER_ID]))


static func _dealer_png_filenames() -> Array:
	var filenames := []
	var dir := DirAccess.open(CROUPIER_DIR)
	if dir == null:
		for dealer_id_item in DISPLAY_NAMES.keys():
			var dealer_id: String = String(dealer_id_item)
			filenames.append("%s.png" % String(dealer_id))
		filenames.sort()
		return filenames
	dir.list_dir_begin()
	var filename: String = dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.begins_with("dealer_") and filename.ends_with(".png"):
			filenames.append(filename)
		filename = dir.get_next()
	dir.list_dir_end()
	filenames.sort()
	return filenames
