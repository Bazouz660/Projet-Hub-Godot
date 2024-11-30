extends Move
class_name Sprint

@export var speed = 10.0

func default_lifecycle(input: InputPackage):
	return best_input_that_can_be_paid(input)

func update(input: InputPackage, delta: float):
	resources.lose_stamina(stamina_cost * delta)
	if resources.stamina < stamina_cost * delta:
		try_force_move("run")

	player.velocity = velocity_by_input(input, delta)
	player.rotation.y = rotation_by_input(input)

func velocity_by_input(input: InputPackage, _delta: float) -> Vector3:
	var y = player.velocity.y
	var direction = Vector3(input.direction.x, 0, input.direction.y).rotated(Vector3.UP, input.camera_rotation.y)
	var velocity = lerp(player.velocity, direction * speed, 0.1)
	velocity.y = y
	return velocity

func rotation_by_input(_input: InputPackage) -> float:
	if player.velocity.length() < 0.1:
		return player.rotation.y
	else:
		return lerp_angle(player.rotation.y, atan2(player.velocity.x, player.velocity.z), 0.1)
