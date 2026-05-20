extends Node

const SAVE_PATH := "user://savefile.json"

func save_game(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file.")
		return
	var json := JSON.stringify(data, "\t")
	file.store_string(json)
	file.close()

func validate_save(data: Dictionary) -> bool:
	return data.has("scene") and typeof(data["scene"]) == TYPE_STRING

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var content := file.get_as_text()
	file.close()
	if content.strip_edges() == "":
		return {}
	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file corrupted or invalid JSON.")
		return {}
	return parsed

func save_exists() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data := load_game()
	return data.has("scene")
