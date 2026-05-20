extends Node2D

@onready var player = $PLAYER
@onready var spawn_start = $Spawn_Start

func _ready():
	player.position = spawn_start.position
