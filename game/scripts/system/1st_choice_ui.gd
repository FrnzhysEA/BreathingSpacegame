extends CanvasLayer

@onready var dialogue_label = $Dialogue/VBoxContainer/ColorRect/RichTextLabel
@onready var progress_bar = $Dialogue/VBoxContainer/ColorRect/ProgressBar
@onready var choice_container = $PanelContainer/VBoxContainer/CenterContainer
@onready var choice_1 = $PanelContainer/VBoxContainer/CenterContainer/HBoxContainer/button_1
@onready var choice_2 = $PanelContainer/VBoxContainer/CenterContainer/HBoxContainer/button_2
@onready var choice_3 = $PanelContainer/VBoxContainer/CenterContainer/HBoxContainer/button_3
@onready var anxiety_meter = $"../UILayer/Control"
@onready var mia_prob = $"../CharacterLayer/MiaProb"
@onready var hd_al = $"../CharacterLayer/HdAl"
@onready var dim_overlay = $"../DimLayer/DimOverlay"

var can_click_mia := false
var anxiety := 0
var waiting_for_choice := false
var waiting_for_enter := false
var is_transitioning := false
var text_queue: Array = []
var scene_stage := 1
var timer_tween: Tween
var accept_cooldown := false

func _ready():
	progress_bar.max_value = 10
	progress_bar.value = 10
	progress_bar.show_percentage = false
	progress_bar.step = 1 
	dialogue_label.bbcode_enabled = true
	choice_1.pressed.connect(_on_choice_1)
	choice_2.pressed.connect(_on_choice_2)
	choice_3.pressed.connect(_on_choice_3)
	_hide_choices()
	anxiety_meter.reset_meter()
	dim_overlay.hide()
	mia_prob.hide()
	hd_al.hide()
	hide()
	start_scene_1()

func start_scene_1():
	show()
	scene_stage = 1
	start_narration([
		["Narration", "Alex enters the classroom and notices Mia sitting quietly."],
		["Narration", "Mia avoids eye contact, she is visibly tense."],
		["Narration", "Alex approached her and talked with her."]
	])

func on_mia_clicked():
	if !can_click_mia:
		return
	can_click_mia = false
	waiting_for_choice = true
	show_choice_1()

func _process(_delta):
	if is_transitioning:
		return
	if waiting_for_enter and not accept_cooldown and Input.is_action_just_pressed("ui_accept"):
		_next_line()

func start_narration(lines: Array):
	text_queue = lines
	waiting_for_enter = true
	can_click_mia = false
	waiting_for_choice = false
	show()
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
		1:
			hide()
			dim_overlay.hide()
			mia_prob.hide()
			hd_al.hide()
			can_click_mia = true
		2:
			show_choice_2()
		3:
			_on_scene_complete()

func update_dialogue(character_name: String, text: String):
	var color = "white"
	match character_name:
		"Alex": color = "cyan"
		"Mia":  color = "pink"

	if character_name == "Narration":
		dialogue_label.parse_bbcode("[color=gray]" + text + "[/color]")
	else:
		dialogue_label.parse_bbcode("[color=" + color + "]" + character_name + ":[/color] " + text)

	dialogue_label.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(dialogue_label, "visible_ratio", 1.0, 1.5)

func show_choice_1():
	show()
	dim_overlay.show()

	# Start everything invisible
	mia_prob.modulate.a = 0
	hd_al.modulate.a = 0
	$Dialogue.modulate.a = 0
	$PanelContainer.modulate.a = 0

	mia_prob.show()
	hd_al.show()

	# Fade them all in together
	var fade = create_tween()
	fade.set_parallel(true)
	fade.tween_property(mia_prob, "modulate:a", 1.0, 0.6)
	fade.tween_property(hd_al, "modulate:a", 1.0, 0.6)
	fade.tween_property($Dialogue, "modulate:a", 1.0, 0.6)
	fade.tween_property($PanelContainer, "modulate:a", 1.0, 0.6)

	await fade.finished

	choice_1.text = "Hey… you okay? You seem off."
	choice_2.text = "You look tired today."
	choice_3.text = "You don't look okay. What's wrong with you?"
	_show_choices()
	start_timer()

func show_choice_2():
	waiting_for_choice = true
	choice_1.text = "Alright… I'll give you space. I'm here if you need me."
	choice_2.text = "Okay… I guess."
	choice_3.text = "Fine, whatever."
	_show_choices()
	start_timer()

func _on_choice_1():
	if !waiting_for_choice:
		return
	if scene_stage == 1:
		add_anxiety(-0.10)
		_after_choice_1("Hey… you okay? You seem off.")
	elif scene_stage == 2:
		add_anxiety(-0.10)
		_end_scene("Alright… I'll give you space. I'm here if you need me.")

func _on_choice_2():
	if !waiting_for_choice:
		return
	if scene_stage == 1:
		add_anxiety(0.05)
		_after_choice_1("You look tired today.")
	elif scene_stage == 2:
		add_anxiety(0.05)
		_end_scene("Okay… I guess.")

func _on_choice_3():
	if !waiting_for_choice:
		return
	if scene_stage == 1:
		add_anxiety(0.20)
		_after_choice_1("You don't look okay. What's wrong with you?")
	elif scene_stage == 2:
		add_anxiety(0.15)
		_end_scene("Fine, whatever.")

func _after_choice_1(player_text: String):
	waiting_for_choice = false
	waiting_for_enter = false
	_hide_choices()
	if timer_tween:
		timer_tween.kill()

	accept_cooldown = true
	is_transitioning = true

	update_dialogue("Alex", player_text)
	await get_tree().create_timer(1.5).timeout

	accept_cooldown = false
	is_transitioning = false

	scene_stage = 2
	await get_tree().create_timer(2.0).timeout

	start_narration([
		["Mia", "I'm fine… just tired."],
		["Alex", "Is it because of the quiz?"],
		["Mia", "…I just need some time alone, okay?"]
	])

func _end_scene(player_text: String):
	waiting_for_choice = false
	waiting_for_enter = false
	_hide_choices()
	if timer_tween:
		timer_tween.kill()

	accept_cooldown = true
	is_transitioning = true

	update_dialogue("Alex", player_text)
	await get_tree().create_timer(1.5).timeout

	accept_cooldown = false
	is_transitioning = false

	scene_stage = 3
	
	await get_tree().create_timer(2.0).timeout

	mia_prob.hide()
	hd_al.position = Vector2(1166, 882)
	
	start_narration([
		["Narration", "Alex steps back as class begins, but his thoughts linger."],
		["Alex", "That didn't sound like just tired…"],
		["Alex", "Maybe I pushed too much…"],
		["Alex", "But something's definitely wrong."]
	])

func _on_scene_complete():
	await get_tree().create_timer(1.5).timeout
	hide()
	dim_overlay.hide()
	mia_prob.modulate.a = 1.0
	hd_al.modulate.a = 1.0
	$Dialogue.modulate.a = 1.0
	$PanelContainer.modulate.a = 1.0
	mia_prob.hide()
	hd_al.hide()
	get_tree().change_scene_to_file("res://scenes/act1/gameplay/phelan&dolan_findingmia.tscn")

func start_timer():
	if timer_tween:
		timer_tween.kill()
	progress_bar.value = 10
	timer_tween = create_tween()
	timer_tween.tween_property(progress_bar, "value", 0, 10)
	timer_tween.tween_callback(_on_timer_expired)

func _on_timer_expired():
	if !waiting_for_choice:
		return
	if scene_stage == 1:
		_on_choice_2()
	elif scene_stage == 2:
		_on_choice_2()

func add_anxiety(amount: float):
	anxiety += amount
	if amount > 0:
		anxiety_meter.add_anxiety(amount)
	else:
		anxiety_meter.reduce_anxiety(abs(amount))

func _show_choices():
	choice_container.show()
	choice_1.show()
	choice_2.show()
	choice_3.show()

func _hide_choices():
	choice_container.hide()
	choice_1.hide()
	choice_2.hide()
	choice_3.hide()
