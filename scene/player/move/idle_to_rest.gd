extends Move
class_name IdleToRest

func default_lifecycle(input) -> String:
	input.actions.sort_custom(container.moves_priority_sort)
	if works_longer_than(DURATION):
		return "rest"
	return highest_priority_move(input)


func on_enter_state():
	humanoid.velocity.x = 0
	humanoid.velocity.z = 0
