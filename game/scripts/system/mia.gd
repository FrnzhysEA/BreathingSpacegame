extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = $Label
@onready var area: Area2D = $Area2D

var tween: Tween
var started_dialogue := false

const NORMAL_COLOR := Color(1, 1, 1)
const HIGHLIGHT_COLOR := Color(1.2, 1.2, 1.2)

func _ready():
	prompt.visible = false
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_input_event)
	area.input_pickable = true

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			interact()

func _on_mouse_entered():
	prompt.visible = true
	start_flicker(true)

func _on_mouse_exited():
	prompt.visible = false
	start_flicker(false)

func interact():
	if started_dialogue:
		return
	started_dialogue = true
	var dialogue = get_tree().current_scene.get_node_or_null("CanvasLayer")
	if dialogue:
		dialogue.on_mia_clicked()

func start_flicker(state: bool):
	if tween:
		tween.kill()
	if state:
		tween = create_tween()
		tween.set_loops()
		tween.tween_property(sprite, "modulate", HIGHLIGHT_COLOR, 0.4)
		tween.tween_property(sprite, "modulate", NORMAL_COLOR, 0.4)
	else:
		sprite.modulate = NORMAL_COLOR
