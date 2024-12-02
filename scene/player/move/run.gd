extends Move
class_name Run

func default_lifecycle(input: InputPackage):
	return best_input_that_can_be_paid(input)
