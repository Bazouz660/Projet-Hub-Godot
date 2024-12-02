extends Move
class_name IdleSwim

func default_lifecycle(input) -> String:
	return best_input_that_can_be_paid(input)

func update(_input: InputPackage, _delta: float):
	humanoid.position.y = humanoid.WATER_LEVEL - humanoid.height
	humanoid.velocity = Vector3.ZERO
