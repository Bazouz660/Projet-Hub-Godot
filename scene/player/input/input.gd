extends Node
class_name InputGatherer

func gather_input() -> InputPackage:
	var new_input = InputPackage.new()
	new_input.camera_rotation = get_node("../Camera").get_pivot().rotation
	
	new_input.direction = Input.get_vector("left", "right", "forward", "backward")
	if new_input.direction != Vector2.ZERO:
		if Input.is_action_just_pressed("roll"):
			new_input.actions.append("roll")
		
		if Input.is_action_pressed("sprint"):
			new_input.actions.append("sprint")
		else:
			new_input.actions.append("run")
	
	if new_input.actions.is_empty():
		new_input.actions.append("idle")
	
	return new_input
