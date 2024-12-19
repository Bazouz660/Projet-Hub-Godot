extends Area3D

signal interacted(player)

func _input(_event) -> void:
	if Input.is_action_just_pressed("interact") and not SceneManager.disable_player_input:
		interacted.emit(get_parent())