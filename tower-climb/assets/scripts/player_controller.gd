extends CharacterBody2D
class_name PlayerController

@export var speed: float = 10.0
@export var jump_power: float = 15.0   # base jump power

var speed_multiplier: float = 30.0
var jump_multiplier: float = -30.0
var direction: float = 0.0
var can_move: bool = true

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var start_position: Vector2
var base_jump_power: float

# Jump buffering / coyote / variable height
@export var jump_buffer_time: float = 0.15
@export var coyote_time: float = 0.10
@export var jump_release_cut_multiplier: float = 0.45

var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_held: bool = false

# Double jump
@export var max_jumps: int = 1     # 1 = normal, 2 = double jump
var jumps_left: int = 1

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	start_position = global_position
	base_jump_power = jump_power
	jumps_left = max_jumps
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	jump_held = false


func _is_shop_open() -> bool:
	var main := get_tree().current_scene
	if main != null and main.has_method("is_shop_open"):
		return main.is_shop_open()
	return false


func _input(event: InputEvent) -> void:
	# Ignore all player input while the shop is open
	if _is_shop_open():
		return
	if not can_move:
		return
	# JUMP INPUT (buffered & variable height)
	if event.is_action_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
		jump_held = true

	if event.is_action_released("jump"):
		jump_held = false
		# Variable jump height: cut jump when button released while going up
		if velocity.y < 0.0:
			velocity.y *= jump_release_cut_multiplier

	# Drop-through platforms on collision mask bit 10
	if event.is_action_pressed("move_down"):
		set_collision_mask_value(10, false)
	else:
		set_collision_mask_value(10, true)


func _physics_process(delta: float) -> void:
	# Completely freeze movement when shop is open
	if _is_shop_open():
		velocity = Vector2.ZERO
		return
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# --- Timers for coyote & jump buffer ---
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_left = max_jumps
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	# --- Buffered / coyote / double jump logic ---
	if jump_buffer_timer > 0.0 and jumps_left > 0:
		if is_on_floor() or coyote_timer > 0.0 or max_jumps > 1:
			velocity.y = jump_power * jump_multiplier
			jumps_left -= 1
			jump_buffer_timer = 0.0
			if is_on_floor() or coyote_timer > 0.0:
				coyote_timer = 0.0

	# --- Gravity ---
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- Horizontal movement ---
	direction = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = direction * speed * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * speed_multiplier)

	move_and_slide()

	_apply_moving_platform_motion()
	_update_visuals()


func _apply_moving_platform_motion() -> void:
	if not is_on_floor():
		return

	var col := get_last_slide_collision()
	if col == null:
		return

	var platform := col.get_collider()
	if platform == null:
		return

	# Moving platforms should set a `last_motion: Vector2` each frame
	var motion = platform.get("last_motion")
	if motion is Vector2:
		global_position += motion


func _update_visuals() -> void:
	# Just flip the sprite when turning
	if direction > 0.0:
		sprite.flip_h = false
	elif direction < 0.0:
		sprite.flip_h = true


# === FLOOR COLLIDER HELPER (for shop logic) ===
func get_floor_collider() -> Node:
	if not is_on_floor():
		return null
	var collision := get_last_slide_collision()
	if collision:
		return collision.get_collider()
	return null


# === SHOP UPGRADE API ===
func increase_jump_power(amount: float) -> void:
	jump_power += amount
	print("Jump power increased to:", jump_power)


func unlock_double_jump() -> void:
	max_jumps = 2
	jumps_left = max_jumps
	print("Double jump unlocked!")
