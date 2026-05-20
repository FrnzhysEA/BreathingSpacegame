class_name MainMenu
extends Control

@onready var title_text = $TitleScreen
@onready var buttons = $MarginContainer/HBoxContainer/VBoxContainer

@onready var start_button = $MarginContainer/HBoxContainer/VBoxContainer/Start as TextureButton
@onready var settings_button = $MarginContainer/HBoxContainer/VBoxContainer/Settings as TextureButton

@onready var settings_overlay = $Settings
@onready var back_button = $Settings/BackButton as TextureButton
@onready var music_slider = $Settings/MarginContainer/VBoxContainer/HBoxContainer/Music_Slider
@onready var sfx_slider = $Settings/MarginContainer/VBoxContainer/HBoxContainer2/SFX_Slider

@onready var quit_button = $MarginContainer/HBoxContainer/VBoxContainer/Quit as TextureButton
@onready var quit_overlay = $Quit
@onready var quit_yes = $Quit/MarginContainer/VBoxContainer/CenterContainer/HBoxContainer/Yes_Button as Button
@onready var quit_no = $Quit/MarginContainer/VBoxContainer/CenterContainer/HBoxContainer/No_Button as Button

const ACT1_SCENE := "res://scenes/cutscenes/intro_scene.tscn"
var fade_started = false

func _ready():
	get_tree().paused = false

	settings_overlay.visible = false
	quit_overlay.visible = false

	settings_overlay.modulate.a = 0
	title_text.modulate.a = 0
	buttons.modulate.a = 0
	quit_overlay.modulate.a = 0

	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1
	music_slider.value = SettingsManager.music_volume * 100

	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 1
	sfx_slider.value = SettingsManager.sfx_volume * 100

	set_menu_buttons_enabled(false)
	handle_connecting_signals()

	await get_tree().create_timer(1.0).timeout
	_fade_in_ui()

func _fade_in_ui():
	if fade_started:
		return
	fade_started = true

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_text, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.2)
	tween.tween_property(buttons, "modulate:a", 1.0, 0.6)
	tween.tween_callback(func():
		set_menu_buttons_enabled(true)
	)

func on_music_changed(value: float) -> void:
	print("music changed: ", value)
	SettingsManager.music_volume = value / 100.0
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func on_sfx_changed(value: float) -> void:
	SettingsManager.sfx_volume = value / 100.0
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func on_back_pressed() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(settings_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		settings_overlay.visible = false
		title_text.visible = true
		buttons.visible = true
	)
	tween.tween_property(title_text, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(buttons, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func():
		set_menu_buttons_enabled(true)
	)

func on_start_pressed() -> void:
	set_menu_buttons_enabled(false)

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(title_text, "modulate:a", 0.0, 1.2)
	tween.parallel().tween_property(buttons, "modulate:a", 0.0, 1.2)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(ACT1_SCENE)
	)

func on_settings_pressed() -> void:
	set_menu_buttons_enabled(false)

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_text, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(buttons, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		title_text.visible = false
		buttons.visible = false
		settings_overlay.visible = true
	)
	tween.tween_property(settings_overlay, "modulate:a", 1.0, 0.4)

func on_quit_pressed() -> void:
	set_menu_buttons_enabled(false)
	title_text.visible = false
	buttons.visible = false

	quit_overlay.visible = true
	quit_overlay.modulate.a = 0

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(quit_overlay, "modulate:a", 1.0, 0.25)

func on_quit_yes() -> void:
	get_tree().quit()

func on_quit_no() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(quit_overlay, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		quit_overlay.visible = false
		title_text.visible = true
		buttons.visible = true
		set_menu_buttons_enabled(true)
	)
	tween.tween_property(title_text, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(buttons, "modulate:a", 1.0, 0.3)

func handle_connecting_signals() -> void:
	start_button.button_down.connect(on_start_pressed)
	settings_button.button_down.connect(on_settings_pressed)
	quit_button.button_down.connect(on_quit_pressed)
	back_button.button_down.connect(on_back_pressed)
	quit_yes.button_down.connect(on_quit_yes)
	quit_no.button_down.connect(on_quit_no)
	music_slider.value_changed.connect(on_music_changed)
	sfx_slider.value_changed.connect(on_sfx_changed)
	
func set_menu_buttons_enabled(enabled: bool) -> void:
	start_button.disabled = not enabled
	settings_button.disabled = not enabled
	quit_button.disabled = not enabled
