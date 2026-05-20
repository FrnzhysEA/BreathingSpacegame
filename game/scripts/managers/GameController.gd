extends Node

var anxiety: float = 0.0
var target_anxiety: float = 0.0
var current_level := 1
var player = null

func save_progress() -> void:
	if player == null:
		return
	var data = {
		"scene": get_tree().current_scene.scene_file_path,
		"player_position": {
			"x": player.global_position.x,
			"y": player.global_position.y
		},
		"anxiety": anxiety,
		"target_anxiety": target_anxiety,
		"level": current_level
	}
	SaveManager.save_game(data)
