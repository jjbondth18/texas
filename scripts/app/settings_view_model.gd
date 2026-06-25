extends RefCounted
class_name SettingsViewModel

var sections: Array[Dictionary] = [
	{"id": "graphics", "label": "Graphics", "route": "settings_graphics"},
	{"id": "audio", "label": "Audio", "route": "settings_audio"},
	{"id": "controls", "label": "Controls", "route": "settings_controls"},
	{"id": "language", "label": "Language", "route": "settings_language"},
	{"id": "motion", "label": "Motion", "route": "settings_motion"},
]

func to_dict() -> Dictionary:
	return {"sections": sections.duplicate(true)}
