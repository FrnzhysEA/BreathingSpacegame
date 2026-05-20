extends Node

var anxiety: float = 0.0
var target_anxiety: float = 0.0
var current_level := 1
var player = null

func add_anxiety(amount: float) -> void:
	target_anxiety += amount

func reset_anxiety() -> void:
	anxiety = 0.0
	target_anxiety = 0.0
	current_level = 1
