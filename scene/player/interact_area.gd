extends Area3D
class_name PlayerInteractArea

signal interacted(player: Player)

func _input(_event) -> void:
	if Input.is_action_just_pressed("interact") and not SceneManager.disable_player_input:
		interacted.emit(get_parent())
