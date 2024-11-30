extends Move
class_name RestToIdle

func default_lifecycle(input) -> String:
	input.actions.sort_custom(moves_priority_sort)
	if works_longer_than(TRANSITION_TIMING):
		return "idle"
	if moves_priority.get(input.actions[0]) > moves_priority.get("rest_to_idle"):
		return input.actions[0]
	return "ok"

func on_enter_state():
	player.velocity.x = 0
	player.velocity.z = 0
