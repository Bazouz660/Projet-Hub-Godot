extends Move
class_name Run

@export var speed = 7.0

func check_relevance(input : InputPackage):
	input.actions.sort_custom(moves_priority_sort)
	if input.actions[0] == "run":
		return "ok"
	return input.actions[0]


func update(input : InputPackage, delta : float):
	player.velocity = velocity_by_input(input, delta)
	player.rotation.y = rotation_by_input(input)


func velocity_by_input(input : InputPackage, _delta : float) -> Vector3:
	var y = player.velocity.y
	var direction = Vector3(input.direction.x, 0, input.direction.y).rotated(Vector3.UP, input.camera_rotation.y)
	var velocity = lerp(player.velocity, direction * speed, 0.1)
	velocity.y = y
	return velocity

func rotation_by_input(_input : InputPackage) -> float:
	if player.velocity.length() < 0.1:
		return player.rotation.y
	else:
		return lerp_angle(player.rotation.y, atan2(player.velocity.x, player.velocity.z), 0.1)
