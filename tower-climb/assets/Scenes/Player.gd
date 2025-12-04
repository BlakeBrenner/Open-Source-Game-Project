extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_force: float = 450.0
@export var gravity: float = 900.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var cam: Camera2D = $Camera2D

var max_height_reached: float = 0.0

func _ready() -> void:
	if cam:
		cam.make_current()

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_update_height()

func _handle_movement(delta: float) -> void:
	var input_dir := _get_horizontal_input()

	# DEBUG: see input value in console
	# (You can comment this out later.)
	print("input_dir: ", input_dir)

	velocity.x = input_dir * speed

	# Flip sprite when moving
	if input_dir != 0.0:
		sprite.flip_h = input_dir < 0.0

	# Gravity + jump
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if _is_jump_just_pressed():
			print("JUMP ACTION DETECTED")  # debug
			velocity.y = -jump_force

	move_and_slide()

func _get_horizontal_input() -> float:
	var dir: float = 0.0

	# Prefer your custom actions if they exist
	if InputMap.has_action("move_left") and InputMap.has_action("move_right"):
		dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	else:
		# Fallback to default UI actions (arrow keys)
		dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	return dir

func _is_jump_just_pressed() -> bool:
	# Prefer custom "jump" if it exists
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump"):
		return true

	# Fallback to default "ui_accept" (space/enter by default)
	if Input.is_action_just_pressed("ui_accept"):
		return true

	return false

func _update_height() -> void:
	if global_position.y < max_height_reached:
		max_height_reached = global_position.y
