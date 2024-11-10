extends Move
class_name Rest

func check_relevance(input) -> String:
	input.actions.sort_custom(moves_priority_sort)
	if input.actions[0] == "idle_to_rest":
		return "rest_to_idle"
	elif moves_priority.get(input.actions[0]) > moves_priority.get("rest"):
		return input.actions[0]
	return "ok"

func on_enter_state():
	player.velocity.x = 0
	player.velocity.z = 0
