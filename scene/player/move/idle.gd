extends Move
class_name Idle

func default_lifecycle(input) -> String:
	return best_input_that_can_be_paid(input)

func on_enter_state():
	humanoid.velocity.x = 0
	humanoid.velocity.z = 0

func update(_input: InputPackage, _delta: float):
	humanoid.velocity.x = 0
	humanoid.velocity.z = 0
