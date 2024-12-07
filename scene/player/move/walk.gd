extends Move

func default_lifecycle(input: InputPackage):
	return best_input_that_can_be_paid(input)

func update(input: InputPackage, delta: float):
	var y = humanoid.velocity.y
	var direction = Vector3(input.direction.x, 0, input.direction.y).rotated(Vector3.UP, input.camera_rotation.y).normalized()
	var delta_pos = get_root_position_delta(delta) * 0.015 # stupid fucking skeleton scale that fucks everything up
	humanoid.velocity = humanoid.get_quaternion() * delta_pos / delta
	humanoid.velocity.y = y