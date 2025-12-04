extends Area2D

signal collected

func _ready() -> void:
	# Make sure the signal is connected
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	# Debug so we know it's actually colliding
	print("Coin touched by: ", body)

	# Simplest possible rule: any CharacterBody2D collects the coin
	if body is CharacterBody2D:
		emit_signal("collected")
		queue_free()
