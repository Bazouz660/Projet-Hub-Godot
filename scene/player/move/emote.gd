extends Move
class_name Emote

@export var emote_duration: float = 0.833

func on_enter_state():
	player.velocity.x = 0
	player.velocity.z = 0

func default_lifecycle(input) -> String:
	input.actions.sort_custom(moves_priority_sort)
	if works_less_than(emote_duration):
		return "ok"
	return input.actions[0]
