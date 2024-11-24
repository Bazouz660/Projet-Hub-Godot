extends Move
class_name Swim

@export var speed = 5.0

func default_lifecycle(input : InputPackage):
	input.actions.sort_custom(moves_priority_sort)
	if input.actions[0] == "swim":
		return "ok"
	return input.actions[0]
	
func on_enter_state():
	player.collision_shape.global_rotation.x = deg_to_rad(90.0)

func on_exit_state():
	player.collision_shape.global_rotation.x = deg_to_rad(0.0)

func update(input : InputPackage, delta : float):
	player.velocity = velocity_by_input(input, delta)
	player.position.y = player.WATER_LEVEL - player.height
	player.rotation.y = rotation_by_input(input)


func velocity_by_input(input : InputPackage, _delta : float) -> Vector3:
	var direction = Vector3(input.direction.x, 0, input.direction.y).rotated(Vector3.UP, input.camera_rotation.y)
	var velocity = lerp(player.velocity, direction * speed, 0.1)
	velocity.y = 0
	return velocity

func rotation_by_input(_input : InputPackage) -> float:
	if player.velocity.length() < 0.1:
		return player.rotation.y
	else:
		return lerp_angle(player.rotation.y, atan2(player.velocity.x, player.velocity.z), 0.1)
