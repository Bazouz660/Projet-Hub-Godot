extends Move
class_name IdleSwim
	
func default_lifecycle(input) -> String:
	input.actions.sort_custom(moves_priority_sort)
	return input.actions[0]

func on_enter_state():
	player.velocity = Vector3.ZERO
	player.position.y = player.WATER_LEVEL - player.height * 1.2
