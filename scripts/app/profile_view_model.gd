extends RefCounted
class_name ProfileViewModel

var sections: Array[Dictionary] = [
	{"id": "overview", "label": "Overview", "route": "profile"},
	{"id": "stats", "label": "Stats", "route": "profile_stats"},
	{"id": "achievements", "label": "Achievements", "route": "profile_achievements"},
	{"id": "cosmetics", "label": "Cosmetics", "route": "profile_cosmetics"},
]

func to_dict() -> Dictionary:
	return {"sections": sections.duplicate(true)}
