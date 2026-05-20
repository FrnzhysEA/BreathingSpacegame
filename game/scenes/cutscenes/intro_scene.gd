extends CanvasLayer

signal narration_finished

const CHAR_READ_RATE = 0.0009

@export var dialogue_json_path := "res://dialogue/intro_dialogue.json"
const NEXT_SCENE := "res://scenes/gameplay/phelan_walking.tscn"

# ── UI ─────────────────────────────
@onready var fade_rect = $Fade
@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/HBoxContainer/Start
@onready var end_symbol = $TextboxContainer/MarginContainer/HBoxContainer/End
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label

@onready var game = get_tree().current_scene.get_node("Game")

@onready var bg1 = game.get_node("BG_1")
@onready var bg2 = game.get_node("BG_2")
@onready var bg3 = game.get_node("BG_3")
@onready var bg4 = game.get_node("BG_4")

# ── STATE ──────────────────────────
enum State { READY, READING, FINISHED }

var current_state = State.READY
var started := false

var text_queue: Array = []
var current_text := ""
var line_index := 0
var tween

var _data := {}
var _steps := []
var _next_scene := ""

# background timing
var bg_map = [0, 0, 1, 1, 2, 2, 2, 3]

# ───────────────────────────────────
# READY
# ───────────────────────────────────
func _ready():
	fade_rect.modulate.a = 1.0

	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 0.8)

	hide_textbox()
	update_background(0)

	_load_dialogue()

# ───────────────────────────────────
# JSON LOADING
# ───────────────────────────────────
func _load_dialogue():
	var file = FileAccess.open(dialogue_json_path, FileAccess.READ)
	if file == null:
		push_error("Cannot open intro dialogue JSON")
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("JSON parse error")
		return

	_data = json.get_data()
	_steps = _data.get("steps", [])
	_next_scene = _data.get("next_scene", NEXT_SCENE)

	# fill queue
	for step in _steps:
		if step.get("type") == "dialogue":
			queue_text(step.get("text", ""))

	# START GAME ONLY AFTER LOADING
	started = true
	current_state = State.READY
	show_textbox()

# ───────────────────────────────────
# PROCESS LOOP
# ───────────────────────────────────
func _process(_delta):
	if !started:
		return

	match current_state:

		State.READY:
			if text_queue.size() > 0:
				display_text()

		State.READING:
			if Input.is_action_just_pressed("ui_accept"):
				_skip_text()

		State.FINISHED:
			if Input.is_action_just_pressed("ui_accept"):
				_advance()

# ───────────────────────────────────
# TEXT SYSTEM
# ───────────────────────────────────
func queue_text(t: String):
	text_queue.append(t)

func display_text():
	current_text = text_queue.pop_front()

	label.text = ""
	start_symbol.text = "*"
	end_symbol.text = ""

	current_state = State.READING
	show_textbox()

	if tween:
		tween.kill()

	tween = create_tween()

	for i in range(current_text.length()):
		tween.tween_callback(func():
			label.text = current_text.substr(0, i + 1)
		).set_delay(i * CHAR_READ_RATE)

	tween.finished.connect(_on_tween_finished, CONNECT_ONE_SHOT)

func _on_tween_finished():
	end_symbol.text = "v"
	current_state = State.FINISHED

func _skip_text():
	if tween:
		tween.kill()

	label.text = current_text
	end_symbol.text = "v"
	current_state = State.FINISHED

# ───────────────────────────────────
# FLOW CONTROL
# ───────────────────────────────────
func _advance():
	line_index += 1

	if line_index < bg_map.size():
		update_background(bg_map[line_index])

	if text_queue.is_empty():
		hide_textbox()
		go_to_next_scene()
	else:
		current_state = State.READY
		hide_textbox()

# ───────────────────────────────────
# BACKGROUND
# ───────────────────────────────────
func update_background(index: int):
	bg1.visible = false
	bg2.visible = false
	bg3.visible = false
	bg4.visible = false

	match index:
		0: bg1.visible = true
		1: bg2.visible = true
		2: bg3.visible = true
		3: bg4.visible = true

# ───────────────────────────────────
# SCENE TRANSITION
# ───────────────────────────────────
func go_to_next_scene():
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.8)

	fade_tween.tween_callback(func():
		get_tree().change_scene_to_file(_next_scene)
	)

# ───────────────────────────────────
# UI HELPERS
# ───────────────────────────────────
func show_textbox():
	textbox_container.show()

func hide_textbox():
	start_symbol.text = ""
	end_symbol.text = ""
	label.text = ""
	textbox_container.hide()
