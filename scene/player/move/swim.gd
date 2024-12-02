extends Move
class_name Swim

func default_lifecycle(input: InputPackage):
	input.actions.sort_custom(container.moves_priority_sort)
	if input.actions[0] == "swim":
		return "ok"
	return input.actions[0]

func on_enter_state():
	humanoid.collision_shape.global_rotation.x = deg_to_rad(90.0)

func on_exit_state():
	humanoid.collision_shape.global_rotation.x = deg_to_rad(0.0)

func update(_input: InputPackage, _delta: float):
	humanoid.position.y = humanoid.WATER_LEVEL - humanoid.height
	humanoid.velocity.y = 0
