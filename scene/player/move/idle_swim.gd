extends Move
class_name IdleSwim

func check_relevance(input) -> String:
	input.actions.sort_custom(moves_priority_sort)
	return input.actions[0]
	
func on_enter_state():
	player.position.y = player.WATER_LEVEL - player.height * 1.2
	player.velocity.y = 0.0
	
func update(input : InputPackage, delta : float):
	player.velocity = velocity_by_input(input, delta)
	player.rotation.y = rotation_by_input(input)

func velocity_by_input(_input : InputPackage, _delta : float) -> Vector3:
	var velocity = lerp(player.velocity, Vector3(0, 0, 0), 0.1)
	velocity.y = 0.0
	return velocity

func rotation_by_input(_input : InputPackage) -> float:
	if player.velocity.length() < 0.1:
		return player.rotation.y
	else:
		return lerp_angle(player.rotation.y, atan2(player.velocity.x, player.velocity.z), 0.1)
