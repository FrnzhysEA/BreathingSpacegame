extends CanvasLayer

@onready var dialogue_label = $Dialogue/VBoxContainer/ColorRect/RichTextLabel
@onready var progress_bar = $Dialogue/VBoxContainer/ColorRect/ProgressBar
@onready var choice_container = $PanelContainer/VBoxContainer/CenterContainer
@onready var choice_1 = $PanelContainer/VBoxContainer/CenterContainer/HBoxContainer/button_1
@onready var choice_2 = $PanelContainer/VBoxContainer/CenterContainer/HBoxContainer/button_2
@onready var choice_3 = $PanelContainer/VBoxContainer/CenterContainer/HBoxContainer/button_3
@onready var anxiety_meter = $"../Control"

var timer_tween
var anxiety := 0
var waiting_for_choice := false
var waiting_for_breath := false
var waiting_for_enter := false
var is_transitioning := false
var accept_cooldown := false

var scene_stage := 1
var breath_phase := 0
var breath_round := 0
var text_queue: Array = []


# ─────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────

func _ready():
	progress_bar.max_value = 10
	progress_bar.value = 10
	progress_bar.show_percentage = false

	dialogue_label.bbcode_enabled = true

	choice_1.pressed.connect(_on_choice_1)
	choice_2.pressed.connect(_on_choice_2)
	choice_3.pressed.connect(_on_choice_3)

	_hide_choices()
	anxiety_meter.reset_meter()
	start_hallway_scene()


# ─────────────────────────────────────────────
#  INPUT
# ─────────────────────────────────────────────

func _process(_delta):
	if waiting_for_breath:
		return
	var seconds_left = int(ceil(progress_bar.value))
	if seconds_left <= 3:
		progress_bar.modulate = Color(1, 0.3, 0.3)
	else:
		progress_bar.modulate = Color(1, 1, 1)

	if is_transitioning:
		return
	if waiting_for_enter and not accept_cooldown and Input.is_action_just_pressed("ui_accept"):
		_next_line()


# ─────────────────────────────────────────────
#  NARRATION SYSTEM
# ─────────────────────────────────────────────

func start_narration(lines: Array):
	text_queue = lines
	waiting_for_enter = true
	waiting_for_choice = false
	_next_line()

func _next_line():
	if is_transitioning:
		return

	if text_queue.is_empty():
		waiting_for_enter = false
		_on_narration_finished()
		return

	var line = text_queue.pop_front()
	is_transitioning = true
	update_dialogue(line[0], line[1])
	await get_tree().create_timer(1.6).timeout
	is_transitioning = false

func _on_narration_finished():
	waiting_for_enter = false
	is_transitioning = false

	match scene_stage:
		1: show_panic_choice_1()
		2: show_panic_choice_2()
		3: _after_choice_narration_done()
		4: _after_choice_2_narration_done()
		5: get_tree().change_scene_to_file("res://scenes/act1/minigame/Main.tscn")

func start_timer():
	if timer_tween:
		timer_tween.kill()

	progress_bar.max_value = 10
	progress_bar.value = 10
	timer_tween = create_tween()
	timer_tween.tween_property(progress_bar, "value", 0, 10)
	timer_tween.set_trans(Tween.TRANS_LINEAR)
	timer_tween.finished.connect(_on_time_up)

func _on_time_up():
	if waiting_for_breath:
		return
	if !waiting_for_choice:
		return
	var choices = [choice_1, choice_2, choice_3]
	var random_choice = choices[randi() % choices.size()]
	random_choice.emit_signal("pressed")


# ─────────────────────────────────────────────
#  DIALOGUE HELPER
# ─────────────────────────────────────────────

func update_dialogue(character_name: String, text: String):
	match character_name:
		"Narration":
			dialogue_label.parse_bbcode("[color=gray]" + text + "[/color]")
		"Alex":
			dialogue_label.parse_bbcode("[color=cyan]Alex:[/color] " + text)
		"Mia":
			dialogue_label.parse_bbcode("[color=pink]Mia:[/color] " + text)

	dialogue_label.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(dialogue_label, "visible_ratio", 1.0, 1.5)

func add_anxiety(amount: float):
	anxiety += amount
	if amount > 0:
		anxiety_meter.add_anxiety(amount)
	else:
		anxiety_meter.reduce_anxiety(abs(amount))

func _hide_choices():
	choice_container.hide()
	choice_1.hide()
	choice_2.hide()
	choice_3.hide()

func _show_choices(c1: String, c2: String, c3: String):
	choice_1.text = c1
	choice_2.text = c2
	choice_3.text = c3
	choice_container.show()
	choice_1.show()
	choice_2.show()
	choice_3.show()


# ─────────────────────────────────────────────
#  CHOICE ROUTING
# ─────────────────────────────────────────────

func _on_choice_1():
	if waiting_for_breath: return
	if !waiting_for_choice: return
	waiting_for_choice = false
	_hide_choices()
	if timer_tween: timer_tween.kill()

	accept_cooldown = true
	is_transitioning = true

	match scene_stage:
		1: _queue_after_panic_choice_1(1)
		2: _queue_after_panic_choice_2(1)

func _on_choice_2():
	if waiting_for_breath: return
	if !waiting_for_choice: return
	waiting_for_choice = false
	_hide_choices()
	if timer_tween: timer_tween.kill()

	accept_cooldown = true
	is_transitioning = true

	match scene_stage:
		1: _queue_after_panic_choice_1(2)
		2: _queue_after_panic_choice_2(2)

func _on_choice_3():
	if waiting_for_breath: return
	if !waiting_for_choice: return
	waiting_for_choice = false
	_hide_choices()
	if timer_tween: timer_tween.kill()

	accept_cooldown = true
	is_transitioning = true

	match scene_stage:
		1: _queue_after_panic_choice_1(3)
		2: _queue_after_panic_choice_2(3)


# ─────────────────────────────────────────────
#  HALLWAY INTRO
# ─────────────────────────────────────────────

func start_hallway_scene():
	scene_stage = 1
	start_narration([
		["Narration", "After class. The hallway slowly empties as students head home."],
		["Narration", "Alex is about to leave when something catches his eye."],
		["Narration", "Mia is crouched on the floor near the lockers, knees pulled tight to her chest."],
		["Narration", "Her shoulders are trembling. Short, ragged breaths. She's trying to hide it."],
		["Alex", "(She's having a panic attack. I need to stay calm — I can't make this worse.)"]
	])


# ─────────────────────────────────────────────
#  CHOICE 1 — FIRST APPROACH
# ─────────────────────────────────────────────

func show_panic_choice_1():
	waiting_for_choice = true
	_show_choices(
		"Mia… hey. I'm right here. You're not alone.",
		"What's wrong?! Do you need me to call someone?!",
		"Should I go get a teacher?"
	)
	start_timer()

func _queue_after_panic_choice_1(index: int):
	var lines: Array = []
	match index:
		1:
			add_anxiety(-0.10)
			lines = [
				["Alex", "Mia… hey. I'm right here. You're not alone."],
				["Mia", "A-Alex… I c-can't… I can't breathe right…"],
				["Alex", "(She recognized me. Okay. Keep going. Stay calm.)"]
			]
		2:
			add_anxiety(0.20)
			lines = [
				["Alex", "What's wrong?! Do you need me to call someone?!"],
				["Mia", "No— no, don't— please just… d-don't make a scene…"],
				["Alex", "(She doesn't want attention. I need to lower my voice.)"]
			]
		3:
			add_anxiety(0.10)
			lines = [
				["Alex", "Should I go get a teacher?"],
				["Mia", "No… please… just— stay. Don't leave me."],
				["Alex", "(She wants me to stay. Okay. Figure this out together.)"]
			]

	scene_stage = 3  # stage 3 = after choice 1 narration, leads to choice 2
	await get_tree().create_timer(0.1).timeout
	accept_cooldown = false
	is_transitioning = false
	start_narration(lines)

func _after_choice_narration_done():
	scene_stage = 2
	show_panic_choice_2()


# ─────────────────────────────────────────────
#  CHOICE 2 — OFFER TO BREATHE TOGETHER
# ─────────────────────────────────────────────

func show_panic_choice_2():
	waiting_for_choice = true
	_show_choices(
		"Can you try breathing with me? Just follow my voice.",
		"Think about something that makes you feel safe.",
		"You need to calm down — people might see you."
	)
	start_timer()

func _queue_after_panic_choice_2(index: int):
	var lines: Array = []
	match index:
		1:
			add_anxiety(-0.15)
			lines = [
				["Alex", "Can you try breathing with me? Just follow my voice."],
				["Mia", "O-okay… okay… I'll… I'll try…"]
			]
		2:
			add_anxiety(0.05)
			lines = [
				["Alex", "Think about something that makes you feel safe."],
				["Mia", "I c-can't think… everything's too loud…"],
				["Alex", "Okay — okay. Then just listen to my voice. That's all."]
			]
		3:
			add_anxiety(0.25)
			lines = [
				["Alex", "You need to calm down — people might see you."],
				["Mia", "I know— I know, I'm sorry— I c-can't help it—"],
				["Alex", "(That was the wrong thing to say. Focus. Help her breathe.)"]
			]

	scene_stage = 4  # stage 4 = after choice 2 narration, leads to breathing
	await get_tree().create_timer(0.1).timeout
	accept_cooldown = false
	is_transitioning = false
	start_narration(lines)

func _after_choice_2_narration_done():
	start_breathing_exercise()


# ─────────────────────────────────────────────
#  BREATHING MINIGAME
# ─────────────────────────────────────────────

func start_breathing_exercise():
	scene_stage = 5
	start_narration([
		["Alex", "Okay Mia… just follow me. We're going to breathe together."],
		["Mia", "…okay…"]
	])

func _on_narration_finished_breathing():
	get_tree().change_scene_to_file("res://scenes/act1/minigame/Main.tscn")
