extends Node

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_VOLUME := 0.5

var music_volume: float = DEFAULT_VOLUME
var sfx_volume: float = DEFAULT_VOLUME

func _ready() -> void:
	load_settings()
	# Wait one frame so AudioManager._ready() has finished
	await get_tree().process_frame
	apply_settings()

func apply_settings() -> void:
	AudioManager.music_player.volume_db = linear_to_db(music_volume)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	music_volume = config.get_value("audio", "music_volume", DEFAULT_VOLUME)
	sfx_volume = config.get_value("audio", "sfx_volume", DEFAULT_VOLUME)
