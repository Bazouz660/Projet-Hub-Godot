extends Move
class_name RestToIdle

@export var DURATION : float = 2.2917

func check_relevance(input) -> String:
	input.actions.sort_custom(moves_priority_sort)
	if works_longer_than(DURATION):
		return "idle"
	if moves_priority.get(input.actions[0]) > moves_priority.get("rest_to_idle"):
		return input.actions[0]
	return "ok"

func on_enter_state():
	player.velocity.x = 0
	player.velocity.z = 0
