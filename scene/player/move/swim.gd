extends Move
class_name Swim

@export var speed = 5.0

func default_lifecycle(input: InputPackage):
	input.actions.sort_custom(container.moves_priority_sort)
	if input.actions[0] == "swim":
		return "ok"
	return input.actions[0]

func on_enter_state():
	humanoid.collision_shape.global_rotation.x = deg_to_rad(90.0)

func on_exit_state():
	humanoid.collision_shape.global_rotation.x = deg_to_rad(0.0)

func update(input: InputPackage, delta: float):
	humanoid.velocity = velocity_by_input(input, delta)
	humanoid.position.y = humanoid.WATER_LEVEL - humanoid.height
	humanoid.rotation.y = rotation_by_input(input)


func velocity_by_input(input: InputPackage, _delta: float) -> Vector3:
	var direction = Vector3(input.direction.x, 0, input.direction.y).rotated(Vector3.UP, input.camera_rotation.y)
	var velocity = lerp(humanoid.velocity, direction * speed, 0.1)
	velocity.y = 0
	return velocity

func rotation_by_input(_input: InputPackage) -> float:
	if humanoid.velocity.length() < 0.1:
		return humanoid.rotation.y
	else:
		return lerp_angle(humanoid.rotation.y, atan2(humanoid.velocity.x, humanoid.velocity.z), 0.1)
