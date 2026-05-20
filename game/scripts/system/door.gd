extends Node2D

@onready var sprite = $Sprite2D
@onready var prompt = $Label

var highlight_tween: Tween
var player_inside := false

const NEXT_SCENE := "res://scenes/gameplay/Phelan_classroom.tscn"

func _ready():
	prompt.visible = false
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		set_highlight(true)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		set_highlight(false)

func _process(delta):
		if player_inside:
			if player_inside and Input.is_action_just_pressed("interact"):enter_door()

func enter_door():
	get_tree().change_scene_to_file(NEXT_SCENE)

func set_highlight(state: bool):
	prompt.visible = state

	if highlight_tween:
		highlight_tween.kill()

	if state:
		highlight_tween = create_tween().set_loops()
		highlight_tween.tween_property(sprite, "modulate", Color(1.3, 1.3, 1.3), 0.4)
		highlight_tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.4)
	else:
		sprite.modulate = Color(1, 1, 1)
