extends CanvasLayer

const NEXT_SCENE := "res://scenes/act1/gameplay/phelan_classroom.tscn"

@onready var fade_rect = $Fade


func _ready():
	# start fully black
	fade_rect.modulate.a = 1.0

	# fade IN
	var fade_in := create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 0.0, 0.8)


func go_to_next_scene():
	# fade OUT
	var fade_out := create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, 0.8)

	fade_out.tween_callback(func():
		get_tree().change_scene_to_file(NEXT_SCENE)
	)
