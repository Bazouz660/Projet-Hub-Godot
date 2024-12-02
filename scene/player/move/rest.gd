extends Move
class_name Rest

func default_lifecycle(input) -> String:
	input.actions.sort_custom(container.moves_priority_sort)
	if input.actions[0] == "idle_to_rest":
		return "rest_to_idle"
	return highest_priority_move(input)


func on_enter_state():
	humanoid.velocity.x = 0
	humanoid.velocity.z = 0
