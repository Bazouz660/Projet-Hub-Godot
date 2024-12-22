extends Move

func default_lifecycle(input: InputPackage):
	return best_input_that_can_be_paid(input)

func update(_input: InputPackage, delta: float):
	var y = humanoid.velocity.y
	var delta_pos = get_root_position_delta(delta) * 0.015 # stupid fucking skeleton scale that fucks everything up
	humanoid.velocity = humanoid.get_quaternion() * delta_pos / delta
	humanoid.velocity.y = y