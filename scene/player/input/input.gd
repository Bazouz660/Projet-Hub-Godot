extends Node
class_name InputGatherer

@onready var player = $".."

func gather_input() -> InputPackage:
	var new_input = InputPackage.new()
	new_input.camera_rotation = get_node("../Camera").get_pivot().rotation

	new_input.direction = Input.get_vector("left", "right", "forward", "backward")

	if !player.is_in_water():
		if !SceneManager.disable_player_input:
			if new_input.direction != Vector2.ZERO:
				if Input.is_action_just_pressed("roll"):
					new_input.actions.append("roll")

				new_input.actions.append("run")

				if Input.is_action_pressed("walk"):
					new_input.actions.append("walk")
				elif Input.is_action_pressed("sprint"):
					new_input.actions.append("sprint")

			if Input.is_action_just_pressed("rest"):
				new_input.actions.append("idle_to_rest")

			if Input.is_action_just_pressed("light_attack"):
				new_input.combat_actions.append("light_attack_pressed")

			if Input.is_action_just_pressed("emote"):
				new_input.actions.append("emote")

		new_input.actions.append("idle")

	else:
		if !SceneManager.disable_player_input:
			if new_input.direction != Vector2.ZERO:
				new_input.actions.append("swim")

		new_input.actions.append("idle_swim")

	return new_input

func create_empty_input() -> InputPackage:
	var new_input = InputPackage.new()
	new_input.direction = Vector2.ZERO
	new_input.actions.append("idle")
	return new_input
