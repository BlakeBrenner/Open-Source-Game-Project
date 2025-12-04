extends StaticBody2D
class_name SpikedPlatform

@onready var hazard_area: Area2D = $Hazard_Area

func _ready() -> void:
	# When the player touches either spike side, trigger game over
	hazard_area.body_entered.connect(_on_hazard_body_entered)


func _on_hazard_body_entered(body: Node) -> void:
	if body is PlayerController:
		var player := body as PlayerController
		player.can_move = false
		
		var main := get_tree().current_scene
		if main != null and main.has_method("show_game_over"):
			main.show_game_over(
				"Ouch!",
				"Impaled by spikes.\nPress reset to try again"
			)
