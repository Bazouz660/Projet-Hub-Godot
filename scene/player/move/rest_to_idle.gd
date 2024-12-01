extends Move
class_name RestToIdle

func default_lifecycle(input) -> String:
	input.actions.sort_custom(container.moves_priority_sort)
	if works_longer_than(DURATION):
		return "idle"
	else:
		return input.actions[0]

func on_enter_state():
	humanoid.velocity.x = 0
	humanoid.velocity.z = 0
