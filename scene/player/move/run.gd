extends Move
class_name Run

func default_lifecycle(input: InputPackage):
	return best_input_that_can_be_paid(input)

func update(_input: InputPackage, delta: float):
	process_root_motion_movement(delta)
