extends CanvasLayer

@onready var dialogue_label = $Dialogue/VBoxContainer/ColorRect/RichTextLabel
@onready var progress_bar = $Dialogue/VBoxContainer/ColorRect/ProgressBar
@onready var choice_container = $PanelContainer/VBoxContainer/CenterContainer
@onready var choice_1 = $PanelContainer/VBoxContainer/CenterContainer/HBoxContainer/button_1
@onready var choice_2 = $PanelContainer/VBoxContainer/CenterContainer/HBoxContainer/button_2
@onready var choice_3 = $PanelContainer/VBoxContainer/CenterContainer/HBoxContainer/button_3
@onready var anxiety_meter = $"../Control"

# ── config ─────────────────────────────────────────────
@export var dialogue_json_path: String = "res://data/dialogue_scene_1.json"

# ── runtime state ──────────────────────────────────────
var timer_tween
var dialogue_tween = null

var anxiety := 0.0
var waiting_for_choice := false
var waiting_for_continue := false
var dialogue_skip_enabled := true

var _data: Dictionary = {}
var _steps: Array = []
var _next_scene := ""
var _chosen_text := ""

signal continue_pressed
signal _choice_made

var _last_chosen_index := 0
var _current_choice_options: Array = []
var _current_choice_step: Dictionary = {}

# ── ready ───────────────────────────────────────────────
func _ready() -> void:
	progress_bar.max_value = 10
	progress_bar.value = 10
	progress_bar.show_percentage = false

	dialogue_label.bbcode_enabled = true

	choice_1.pressed.connect(_on_choice_pressed.bind(0))
	choice_2.pressed.connect(_on_choice_pressed.bind(1))
	choice_3.pressed.connect(_on_choice_pressed.bind(2))

	_hide_choices()
	anxiety_meter.reset_meter()

	_load_and_start()

# ── input handling ──────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if waiting_for_choice:
		return

	if waiting_for_continue and dialogue_skip_enabled:
		if event.is_pressed():
			_skip_dialogue()

func _skip_dialogue() -> void:
	waiting_for_continue = false

	if dialogue_tween:
		dialogue_tween.kill()
		dialogue_tween = null

	emit_signal("continue_pressed")

# ── JSON loading ────────────────────────────────────────
func _load_and_start() -> void:
	var file = FileAccess.open(dialogue_json_path, FileAccess.READ)
	if file == null:
		push_error("Cannot open JSON")
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("JSON parse error")
		return

	_data = json.get_data()
	_steps = _data.get("steps", [])
	_next_scene = _data.get("next_scene", "")

	await _run_steps(_steps)

# ── step runner ─────────────────────────────────────────
func _run_steps(steps: Array) -> void:
	for step in steps:
		await _execute_step(step)

	if steps == _steps and _next_scene != "":
		get_tree().change_scene_to_file(_next_scene)

func _execute_step(step: Dictionary) -> void:
	match step.get("type", ""):
		"dialogue":
			await _play_dialogue(step)
		"choice":
			await _play_choice(step)
		"sequence":
			await _run_steps(step.get("steps", []))
		_:
			push_warning("Unknown step type")

# ── dialogue system ─────────────────────────────────────
func _play_dialogue(step: Dictionary) -> void:
	var character: String = step.get("character", "")
	var raw_text: String = step.get("text", "")
	var duration: float = step.get("duration", 0.0)
	dialogue_skip_enabled = step.get("skippable", true)

	var text = raw_text.replace("{chosen_text}", _chosen_text)

	update_dialogue(character, text)

	dialogue_label.visible_ratio = 0.0
	dialogue_tween = create_tween()
	dialogue_tween.tween_property(dialogue_label, "visible_ratio", 1.0, 1.2)

	# TIMED DIALOGUE
	if duration > 0:
		waiting_for_continue = true

		var timer = get_tree().create_timer(duration)
		await timer.timeout

		if waiting_for_continue:
			waiting_for_continue = false
			emit_signal("continue_pressed")

		await continue_pressed
		return

	# MANUAL DIALOGUE
	waiting_for_continue = true
	await continue_pressed
	waiting_for_continue = false

# ── choice system ───────────────────────────────────────
func _play_choice(step: Dictionary) -> void:
	_current_choice_step = step
	var options: Array = step.get("options", [])

	_show_choices(options)
	start_timer()

	waiting_for_choice = true
	await _choice_made
	waiting_for_choice = false

	_hide_choices()

	if timer_tween:
		timer_tween.kill()

	var chosen_option = options[_last_chosen_index]
	var next_id: String = chosen_option.get("next_step_id", "")

	if next_id != "":
		var seq = _find_step_by_id(next_id)
		if seq:
			await _execute_step(seq)

func _on_choice_pressed(index: int) -> void:
	if !waiting_for_choice:
		return

	var options: Array = _current_choice_step.get("options", [])
	var option = options[index]

	_last_chosen_index = index

	add_anxiety(option.get("anxiety_delta", 0.0))

	_chosen_text = option.get("text", "")

	emit_signal("_choice_made")

func _show_choices(options: Array) -> void:
	_current_choice_options = options
	var buttons = [choice_1, choice_2, choice_3]

	for i in range(buttons.size()):
		if i < options.size():
			buttons[i].text = options[i].get("text", "")
			buttons[i].show()
		else:
			buttons[i].hide()

	choice_container.show()

func _hide_choices() -> void:
	choice_container.hide()
	choice_1.hide()
	choice_2.hide()
	choice_3.hide()

func _find_step_by_id(id: String) -> Dictionary:
	for step in _steps:
		if step.get("id", "") == id:
			return step
	return {}

# ── timer ───────────────────────────────────────────────
func start_timer() -> void:
	if timer_tween:
		timer_tween.kill()

	progress_bar.value = 10
	timer_tween = create_tween()
	timer_tween.tween_property(progress_bar, "value", 0, 10)
	timer_tween.set_trans(Tween.TRANS_LINEAR)
	timer_tween.finished.connect(_on_time_up)

func _on_time_up() -> void:
	if !waiting_for_choice:
		return
	_on_choice_pressed(randi() % _current_choice_options.size())

func _process(_delta: float) -> void:
	if progress_bar.value <= 3:
		progress_bar.modulate = Color(1, 0.3, 0.3)
	else:
		progress_bar.modulate = Color(1, 1, 1)

# ── anxiety ─────────────────────────────────────────────
func add_anxiety(amount: float) -> void:
	anxiety += amount
	if amount > 0:
		anxiety_meter.add_anxiety(amount)
	else:
		anxiety_meter.reduce_anxiety(abs(amount))

# ── dialogue UI ─────────────────────────────────────────
func update_dialogue(character_name: String, text: String) -> void:
	var name_color: String
	match character_name:
		"Alex": name_color = "cyan"
		"Mia": name_color = "pink"
		_: name_color = "white"

	if character_name == "Narration":
		dialogue_label.parse_bbcode("[color=gray]" + text + "[/color]")
	else:
		dialogue_label.parse_bbcode(
			"[color=" + name_color + "]" + character_name + ":[/color] " + text
		)

	dialogue_label.visible_ratio = 0.0
