extends Move

func default_lifecycle(input: InputPackage):
	return best_input_that_can_be_paid(input)

func update(input: InputPackage, delta: float):
	process_default_movement(input, delta)