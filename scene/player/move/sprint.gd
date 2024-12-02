extends Move
class_name Sprint

@export var continuous_stamina_cost = 10.0

func default_lifecycle(input: InputPackage):
	return best_input_that_can_be_paid(input)

func update(input: InputPackage, delta: float):
	resources.lose_stamina(continuous_stamina_cost * delta)
	if resources.stamina < continuous_stamina_cost * delta:
		try_force_move("run")

	process_default_movement(input, delta)
