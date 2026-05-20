extends Control

@onready var dial: TextureRect = $AnxietyMeter_ArmDial
@onready var cover: TextureRect = $AnxietyMeter_Cover

var anxiety: float = 0.0
var target_anxiety: float = 0.0
var lerp_speed: float = 2.5

const MIN_ANGLE: float = -90.0  # LEFT  = LOW anxiety
const MAX_ANGLE: float = 90.0   # RIGHT = HIGH anxiety

signal anxiety_maxed
signal anxiety_cleared

func _ready() -> void:
	size = Vector2(200, 200)
	position = Vector2(20, 20)
	dial.texture  = load("res://assets/art/AnxietyMeter_ArmDial.png")
	cover.texture = load("res://assets/art/AnxietyMeter_Cover.png")
	await get_tree().process_frame
	dial.pivot_offset = Vector2(dial.size.x / 2.0, dial.size.y)
	cover.z_index = 0
	dial.z_index  = 1
	# ── Restore from GameController ──
	anxiety        = GameController.anxiety
	target_anxiety = GameController.target_anxiety
	dial.rotation_degrees = lerp(MIN_ANGLE, MAX_ANGLE, (anxiety + 1.0) / 2.0)

func _process(delta: float) -> void:
	anxiety = lerp(anxiety, target_anxiety, lerp_speed * delta)
	anxiety = clamp(anxiety, -1.0, 1.0)
	dial.rotation_degrees = lerp(MIN_ANGLE, MAX_ANGLE, (anxiety + 1.0) / 2.0)
	# ── Keep GameController in sync ──
	GameController.anxiety = anxiety
	if anxiety >= 0.99 and target_anxiety >= 1.0:
		emit_signal("anxiety_maxed")
	if anxiety <= -0.99 and target_anxiety <= -1.0:
		emit_signal("anxiety_cleared")

# ── Bad choice → needle swings RIGHT ──
func add_anxiety(amount: float) -> void:
	target_anxiety = clamp(target_anxiety + amount, -1.0, 1.0)
	GameController.target_anxiety = target_anxiety

# ── Good choice → needle swings LEFT ──
func reduce_anxiety(amount: float) -> void:
	target_anxiety = clamp(target_anxiety - amount, -1.0, 1.0)
	GameController.target_anxiety = target_anxiety

func is_maxed() -> bool:
	return target_anxiety >= 1.0

func reset_meter() -> void:
	anxiety = 0.0
	target_anxiety = 0.0
	GameController.anxiety = 0.0
	GameController.target_anxiety = 0.0
