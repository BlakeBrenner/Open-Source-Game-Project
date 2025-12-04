extends Node2D

# Scenes
@export var small_platform_scene: PackedScene
@export var big_platform_scene: PackedScene
@export_range(0.0, 1.0) var big_platform_chance: float = 0.3

@export var bonus_platform_scene: PackedScene
@export_range(0.0, 1.0) var bonus_platform_chance: float = 0.1   # 10% bonus

@export var moving_platform_scene: PackedScene
@export_range(0.0, 1.0) var moving_platform_chance: float = 0.15 # 15% moving

@export var spiked_platform_scene: PackedScene
@export_range(0.0, 1.0) var spiked_platform_chance: float = 0.1   # 10% spiked

@export var shop_platform_scene: PackedScene
@export var shop_height_interval: float = 1000.0

@export var coin_scene: PackedScene
@export var coin_chance: float = 0.4   # normal platforms

# Node paths
@export var platforms_path: NodePath = "../Platforms"
@export var coins_path: NodePath = "../Coins"
@export var player_path: NodePath = "../Player"

# Base vertical spacing (these become *maximums*, clamped by jump reach)
@export var min_gap_y: float = 45.0
@export var max_gap_y: float = 80.0

# Base horizontal spacing (also clamped by jump reach)
@export var max_horizontal_step: float = 150.0
@export var min_horizontal_step: float = 40.0
@export var recent_platforms_to_avoid: int = 3

# Zig-zag behaviour
@export_range(0.0, 1.0) var direction_change_chance: float = 0.6

# Horizontal bounds for the whole tower
@export var min_x: float = -200.0
@export var max_x: float = 200.0

# Pre-spawn count
@export var max_platforms_above: int = 15

# Spike safety
const SPIKE_HORIZONTAL_CLEARANCE: float = 40.0
const SPIKE_VERTICAL_CLEARANCE: float = 40.0

var platforms_parent: Node2D
var coins_parent: Node2D
var player: Node2D
var highest_y: float = 0.0

var last_horizontal_dir: float = 0.0

# For shop platform heights
var base_y: float = 0.0
var next_shop_height: float = 0.0


func _ready() -> void:
	randomize()

	if has_node(platforms_path):
		platforms_parent = get_node(platforms_path) as Node2D
	else:
		push_error("PlatformSpawner: Node not found at platforms_path: %s" % platforms_path)
		return

	if has_node(player_path):
		player = get_node(player_path) as Node2D
	else:
		push_error("PlatformSpawner: Node not found at player_path: %s" % player_path)
		return

	if has_node(coins_path):
		coins_parent = get_node(coins_path) as Node2D
	else:
		push_error("PlatformSpawner: Node not found at coins_path: %s" % coins_path)
		return

	base_y = player.global_position.y
	next_shop_height = shop_height_interval

	if platforms_parent.get_child_count() > 0:
		var first_child := platforms_parent.get_child(0) as Node2D
		highest_y = first_child.global_position.y
		for p in platforms_parent.get_children():
			var p_node := p as Node2D
			highest_y = min(highest_y, p_node.global_position.y)
	else:
		highest_y = player.global_position.y + 50.0

	# random initial zig-zag direction
	if randf() < 0.5:
		last_horizontal_dir = -1.0
	else:
		last_horizontal_dir = 1.0

	for i in range(max_platforms_above):
		_spawn_reachable_platform()


func _process(delta: float) -> void:
	if player.global_position.y - 200.0 < highest_y:
		_spawn_reachable_platform()


func _spawn_reachable_platform() -> void:
	# --- compute reachability based on current player stats ---
	var limits: Vector2 = _compute_jump_limits()
	var max_v_gap: float = min(max_gap_y, limits.x)
	var min_v_gap_local: float = min(min_gap_y, max_v_gap * 0.9)

	if max_v_gap <= 0.0:
		max_v_gap = max_gap_y
		min_v_gap_local = min_gap_y

	# our vertical gap is always <= what the player can jump
	var gap_y: float = randf_range(min_v_gap_local, max_v_gap)
	var new_y: float = highest_y - gap_y

	var prev_x: float
	if platforms_parent.get_child_count() > 0:
		prev_x = _get_top_platform().global_position.x
	else:
		prev_x = player.global_position.x

	prev_x = clamp(prev_x, min_x, max_x)

	var recent_platforms: Array = _get_recent_top_platforms(recent_platforms_to_avoid)

	# horizontal limits from jump
	var max_h_allowed: float = min(max_horizontal_step, limits.y)
	if max_h_allowed < min_horizontal_step:
		max_h_allowed = min_horizontal_step
	var min_h_local: float = min(min_horizontal_step, max_h_allowed * 0.9)

	# check height for shop platforms
	var height_from_start: float = base_y - new_y
	var force_shop_platform: bool = false
	if shop_platform_scene != null and height_from_start >= next_shop_height:
		force_shop_platform = true
		next_shop_height += shop_height_interval

	var new_x: float = prev_x

	# --- horizontal placement (zig-zag) ---
	if force_shop_platform:
		new_x = _place_shop_side(prev_x, recent_platforms, min_h_local, max_h_allowed)
	else:
		new_x = _place_normal_zigzag(prev_x, recent_platforms, min_h_local, max_h_allowed)

	# --- choose platform scene ---
	var scene: PackedScene
	if force_shop_platform:
		scene = shop_platform_scene
	else:
		scene = _pick_platform_scene()

	if scene == null:
		push_warning("PlatformSpawner: No platform scenes assigned!")
		return

	var is_spike: bool = (spiked_platform_scene != null and scene == spiked_platform_scene)

	# 1) Don't spawn spiked platforms directly UNDER another platform
	if is_spike and _has_platform_above_close(new_x, new_y):
		scene = _pick_non_spiked_scene()
		is_spike = false

	# 2) Don't spawn platforms directly OVER spikes – push them to the side
	if not is_spike:
		new_x = _avoid_spike_column(new_x, new_y)

	if scene == null:
		return

	# instantiate final platform
	var platform := scene.instantiate() as Node2D
	platform.global_position = Vector2(new_x, new_y)
	platforms_parent.add_child(platform)

	var is_bonus: bool = (bonus_platform_scene != null and scene == bonus_platform_scene)

	# coins: not on shop platforms (unless you want them there)
	if coin_scene != null:
		if is_bonus:
			_spawn_coin_at(Vector2(new_x - 24.0, new_y - 40.0))
			_spawn_coin_at(Vector2(new_x,         new_y - 52.0))
			_spawn_coin_at(Vector2(new_x + 24.0,  new_y - 40.0))
		elif (not force_shop_platform) and randf() < coin_chance:
			_spawn_coin_at(Vector2(new_x, new_y - 40.0))

	highest_y = new_y


# =========================
# JUMP LIMITS (core of reachability)
# =========================
# Returns Vector2(x = max_vertical_gap, y = max_horizontal_distance)
func _compute_jump_limits() -> Vector2:
	# defaults if we can't read player data
	var default_vertical: float = max_gap_y
	var default_horizontal: float = max_horizontal_step

	if player == null:
		return Vector2(default_vertical, default_horizontal)

	var pc := player as PlayerController
	if pc == null:
		return Vector2(default_vertical, default_horizontal)

	var g: float = pc.gravity
	# jump_multiplier is negative in your script, so invert sign
	var jump_vel: float = -pc.jump_power * pc.jump_multiplier

	if g <= 0.0 or jump_vel <= 0.0:
		return Vector2(default_vertical, default_horizontal)

	# time to apex, height of jump (simple physics)
	var t_apex: float = jump_vel / g
	var h: float = (jump_vel * jump_vel) / (2.0 * g)

	# horizontal speed from your controller
	var horiz_speed: float = pc.speed * pc.speed_multiplier
	var horiz_reach: float = horiz_speed * t_apex

	# Safety factors so jumps aren't frame-perfect
	var max_vertical_safe: float = h * 0.75
	var max_horizontal_safe: float = horiz_reach * 0.9

	return Vector2(max_vertical_safe, max_horizontal_safe)


# =========================
# placement helpers
# =========================
func _place_shop_side(prev_x: float, recent_platforms: Array, min_h: float, max_h: float) -> float:
	var dir: float = _choose_horizontal_dir()
	var new_x: float = prev_x
	var found: bool = false

	for attempt in range(20):
		var magnitude: float = randf_range(min_h, max_h)
		var candidate_x: float = clamp(prev_x + magnitude * dir, min_x, max_x)

		var ok: bool = true
		for p in recent_platforms:
			var plat := p as Node2D
			if abs(candidate_x - plat.global_position.x) < min_h:
				ok = false
				break

		if ok:
			new_x = candidate_x
			last_horizontal_dir = dir
			found = true
			break

		dir = -dir  # flip side and retry

	if not found:
		var fallback_dir: float = _choose_horizontal_dir()
		new_x = clamp(prev_x + fallback_dir * min_h, min_x, max_x)
		last_horizontal_dir = fallback_dir

	return new_x


func _place_normal_zigzag(prev_x: float, recent_platforms: Array, min_h: float, max_h: float) -> float:
	var new_x: float = prev_x
	var found_valid: bool = false
	var dir: float = _choose_horizontal_dir()

	for attempt in range(20):
		var magnitude: float = randf_range(min_h, max_h)
		var offset: float = magnitude * dir
		var candidate_x: float = clamp(prev_x + offset, min_x, max_x)

		var ok: bool = true
		for p in recent_platforms:
			var plat := p as Node2D
			if abs(candidate_x - plat.global_position.x) < min_h:
				ok = false
				break

		if ok:
			new_x = candidate_x
			found_valid = true
			last_horizontal_dir = dir
			break

		if randf() < 0.5:
			dir = -dir

	if not found_valid:
		var fallback_dir: float = _choose_horizontal_dir()
		new_x = clamp(prev_x + fallback_dir * min_h, min_x, max_x)
		last_horizontal_dir = fallback_dir

	return new_x


# =========================
# spike safety helpers
# =========================
func _has_platform_above_close(x: float, y: float) -> bool:
	for c in platforms_parent.get_children():
		var plat := c as Node2D
		var py: float = plat.global_position.y
		var px: float = plat.global_position.x
		if py < y and abs(px - x) < SPIKE_HORIZONTAL_CLEARANCE and (y - py) < SPIKE_VERTICAL_CLEARANCE:
			return true
	return false


func _avoid_spike_column(x: float, y: float) -> float:
	var result: float = x

	for c in platforms_parent.get_children():
		if c is SpikedPlatform:
			var spike := c as Node2D
			var sx: float = spike.global_position.x
			var sy: float = spike.global_position.y

			# only care about spikes BELOW this platform
			if sy > y and (sy - y) < SPIKE_VERTICAL_CLEARANCE:
				if abs(sx - result) < SPIKE_HORIZONTAL_CLEARANCE:
					if result <= sx:
						result = sx - SPIKE_HORIZONTAL_CLEARANCE
					else:
						result = sx + SPIKE_HORIZONTAL_CLEARANCE
					result = clamp(result, min_x, max_x)

	return result


# =========================
# platform type selection
# =========================
func _choose_horizontal_dir() -> float:
	if last_horizontal_dir == 0.0:
		return -1.0 if randf() < 0.5 else 1.0

	if randf() < direction_change_chance:
		return -last_horizontal_dir
	return last_horizontal_dir


func _pick_platform_scene() -> PackedScene:
	# 1) Bonus platforms first
	if bonus_platform_scene != null and randf() < bonus_platform_chance:
		return bonus_platform_scene

	# 2) Spiked platforms
	if spiked_platform_scene != null and randf() < spiked_platform_chance:
		return spiked_platform_scene

	# 3) Moving platforms
	if moving_platform_scene != null and randf() < moving_platform_chance:
		return moving_platform_scene

	# 4) Normal static platforms
	if small_platform_scene == null and big_platform_scene == null:
		return null
	if small_platform_scene != null and big_platform_scene == null:
		return small_platform_scene
	if small_platform_scene == null and big_platform_scene != null:
		return big_platform_scene

	return big_platform_scene if randf() < big_platform_chance else small_platform_scene


func _pick_non_spiked_scene() -> PackedScene:
	# same as above but NEVER returns spiked_platform_scene
	if bonus_platform_scene != null and randf() < bonus_platform_chance:
		return bonus_platform_scene

	if moving_platform_scene != null and randf() < moving_platform_chance:
		return moving_platform_scene

	if small_platform_scene == null and big_platform_scene == null:
		return null
	if small_platform_scene != null and big_platform_scene == null:
		return small_platform_scene
	if small_platform_scene == null and big_platform_scene != null:
		return big_platform_scene

	return big_platform_scene if randf() < big_platform_chance else small_platform_scene


# =========================
# coins + helpers
# =========================
func _spawn_coin_at(pos: Vector2) -> void:
	var coin := coin_scene.instantiate() as Area2D
	coin.global_position = pos
	coins_parent.add_child(coin)

	var main := get_tree().current_scene
	if main != null and main.has_method("register_coin"):
		main.register_coin(coin)


func _get_top_platform() -> Node2D:
	var first := platforms_parent.get_child(0) as Node2D
	var best: Node2D = first
	var best_y: float = first.global_position.y

	for c in platforms_parent.get_children():
		var plat := c as Node2D
		if plat.global_position.y < best_y:
			best = plat
			best_y = plat.global_position.y

	return best


func _get_recent_top_platforms(count: int) -> Array:
	var result: Array = []
	var candidates: Array = []

	for c in platforms_parent.get_children():
		candidates.append(c)

	while candidates.size() > 0 and result.size() < count:
		var best_index: int = 0
		var best_y: float = (candidates[0] as Node2D).global_position.y

		for i in range(1, candidates.size()):
			var y: float = (candidates[i] as Node2D).global_position.y
			if y < best_y:
				best_y = y
				best_index = i

		result.append(candidates[best_index])
		candidates.remove_at(best_index)

	return result
