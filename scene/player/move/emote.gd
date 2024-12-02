extends Move
class_name Emote

func default_lifecycle(input: InputPackage):
	if works_longer_than(DURATION):
		return best_input_that_can_be_paid(input)
	return highest_priority_move(input)

func on_enter_state():
	humanoid.velocity.x = 0
	humanoid.velocity.z = 0