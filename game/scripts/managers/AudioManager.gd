extends Node

var music_player := AudioStreamPlayer.new()
const BGM_PATH := "res://assets/audio/breathing-space_bgm.mp3"

func _ready() -> void:
	add_child(music_player)
	music_player.stream = load(BGM_PATH)
	music_player.stream.loop = true
	music_player.play()
