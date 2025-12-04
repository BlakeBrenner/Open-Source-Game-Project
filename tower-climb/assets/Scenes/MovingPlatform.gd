extends StaticBody2D
class_name MovingPlatform

@export var amplitude: float = 80.0   # how far left/right to move
@export var speed: float = 1.0        # how fast to move
@export var phase_offset: float = 0.0 # randomize start phase if you want

var origin: Vector2
var time: float = 0.0

# Used by PlayerController to ride the platform
var last_motion: Vector2 = Vector2.ZERO
var _last_position: Vector2


func _ready() -> void:
	origin = global_position
	_last_position = origin


func _physics_process(delta: float) -> void:
	time += delta * speed

	# Simple sine-wave horizontal motion
	var new_x = origin.x + sin(time + phase_offset) * amplitude
	var new_pos = Vector2(new_x, origin.y)

	# Compute how much we moved this frame
	last_motion = new_pos - global_position

	global_position = new_pos
	_last_position = new_pos


func is_moving_platform() -> bool:
	return true
