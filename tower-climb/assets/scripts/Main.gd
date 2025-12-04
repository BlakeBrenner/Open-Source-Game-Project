extends Node2D

@onready var player: PlayerController = $Player
@onready var ui_root: CanvasLayer = $UI
@onready var score_label: Label = $UI/ScoreLabel
@onready var coin_label: Label = $UI/CoinLabel

# SHOP UI
@onready var shop_panel: Control = $UI/Panel
@onready var buy_jump_button: Button = $UI/Panel/BuyJumpButton
@onready var buy_double_button: Button = $UI/Panel/BuyDoubleJump
@onready var close_shop_button: Button = $UI/Panel/CloseShop

# GAME OVER UI
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var title_label: Label = $UI/GameOverPanel/TitleLabel
@onready var hint_label: Label = $UI/GameOverPanel/HintLabel

# === EXPORTED SETTINGS ===
@export var jump_upgrade_cost: int = 20
@export var double_jump_cost: int = 100
@export var death_fall_distance: float = 300.0

# === RUNTIME STATE ===
var coins: int = 0
var start_y: float

var shop_opened: bool = false
var is_game_over: bool = false

# score tracking
var best_height: int = 0

# Shop navigation
var shop_buttons: Array[Button] = []
var shop_index: int = 0


func _ready() -> void:
	start_y = player.global_position.y

	# Hide UI panels on start
	shop_panel.visible = false
	game_over_panel.visible = false

	# Always process UI even while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
	shop_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	# Button list for navigation
	shop_buttons = [buy_jump_button, buy_double_button, close_shop_button]

	# Button signals
	buy_jump_button.pressed.connect(_on_buy_jump_pressed)
	buy_double_button.pressed.connect(_on_buy_double_pressed)
	close_shop_button.pressed.connect(_on_close_shop_pressed)

	_update_coin_label()
	_update_shop_texts()
	_update_shop_selection()


func _process(delta: float) -> void:
	if is_game_over:
		return

	# current height
	var height := int(start_y - player.global_position.y)
	score_label.text = "Height: %d" % height

	# record best height reached this run
	if height > best_height:
		best_height = height

	_check_shop_trigger_on_shop_platform()

	# Game over check (fell too far below start)
	if player.global_position.y > start_y + death_fall_distance:
		show_game_over()


func _check_shop_trigger_on_shop_platform() -> void:
	if shop_opened:
		return
	if not player.is_on_floor():
		return

	var floor := player.get_floor_collider()
	if floor == null:
		return

	# Only open on special shop platforms
	if floor.has_method("is_shop_platform") and floor.is_shop_platform():
		var shop_platform := floor as ShopPlatform
		if shop_platform != null:
			if shop_platform.shop_used:
				return
			shop_platform.shop_used = true

		_open_shop()


# =========================
# SHOP INPUT + RESET
# =========================
func _unhandled_input(event: InputEvent) -> void:
	# --- Game Over Reset ---
	if is_game_over:
		if event.is_action_pressed("reset_player"):
			get_tree().paused = false
			get_tree().reload_current_scene()
		return

	# --- Shop navigation ---
	if not shop_opened:
		return

	if event.is_action_pressed("move_right"):
		shop_index = (shop_index + 1) % shop_buttons.size()
		_update_shop_selection()

	elif event.is_action_pressed("move_left"):
		shop_index = (shop_index - 1 + shop_buttons.size()) % shop_buttons.size()
		_update_shop_selection()

	elif event.is_action_pressed("jump"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused == buy_jump_button:
			_on_buy_jump_pressed()
		elif focused == buy_double_button:
			_on_buy_double_pressed()
		elif focused == close_shop_button:
			_on_close_shop_pressed()
		else:
			match shop_index:
				0: _on_buy_jump_pressed()
				1: _on_buy_double_pressed()
				2: _on_close_shop_pressed()


func _update_shop_selection() -> void:
	for i in range(shop_buttons.size()):
		if i == shop_index:
			shop_buttons[i].grab_focus()


func _update_shop_texts() -> void:
	buy_jump_button.text = "Jump +2 (%d coins)" % jump_upgrade_cost
	buy_double_button.text = "Double Jump (%d coins)" % double_jump_cost
	close_shop_button.text = "Close shop"


# =========================
# COIN SYSTEM
# =========================
func register_coin(coin: Area2D) -> void:
	if not coin.body_entered.is_connected(_on_coin_body_entered):
		coin.body_entered.connect(_on_coin_body_entered.bind(coin))


func _on_coin_body_entered(body: Node, coin: Area2D) -> void:
	if body == player:
		coins += 1
		_update_coin_label()
		coin.queue_free()


func _update_coin_label() -> void:
	coin_label.text = "Coins: %d" % coins


# =========================
# SHOP LOGIC
# =========================
func _open_shop() -> void:
	if is_game_over:
		return

	shop_opened = true
	shop_index = 0
	shop_panel.visible = true
	_update_shop_selection()

	get_tree().paused = true


func _close_shop() -> void:
	shop_opened = false
	shop_panel.visible = false
	get_tree().paused = false


func _on_close_shop_pressed() -> void:
	_close_shop()


func _on_buy_jump_pressed() -> void:
	if coins >= jump_upgrade_cost:
		coins -= jump_upgrade_cost
		_update_coin_label()
		player.increase_jump_power(2.0)
	else:
		print("Not enough coins")


func _on_buy_double_pressed() -> void:
	if player.max_jumps >= 2:
		print("Already unlocked")
		return

	if coins >= double_jump_cost:
		coins -= double_jump_cost
		_update_coin_label()
		player.unlock_double_jump()
	else:
		print("Not enough coins")


# =========================
# GAME OVER
# =========================
func show_game_over(
	title: String = "Game Over",
	hint: String = "Press reset to try again"
) -> void:
	if is_game_over:
		return

	is_game_over = true

	game_over_panel.visible = true
	title_label.text = title

	# Show score on the game over screen
	var score_text := "Height reached: %d" % best_height
	hint_label.text = "%s\n%s" % [score_text, hint]

	shop_opened = false
	shop_panel.visible = false

	get_tree().paused = true


# =========================
# API FOR OTHER NODES
# =========================
func is_shop_open() -> bool:
	return shop_opened
