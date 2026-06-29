extends RefCounted
class_name SettingsViewModel

var sections: Array[Dictionary] = [
	{"id": "audio", "label": "Audio", "route": "settings_audio"},
	{"id": "gameplay", "label": "Gameplay", "route": "settings_controls"},
	{"id": "display", "label": "Display", "route": "settings_graphics"},
	{"id": "account_privacy", "label": "Account & Privacy", "route": "settings_language"},
	{"id": "advanced", "label": "Advanced", "route": "settings_motion"},
]

func to_dict() -> Dictionary:
	return {"sections": sections.duplicate(true)}
