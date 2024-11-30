extends Move

func default_lifecycle(input: InputPackage):
	if works_longer_than(TRANSITION_TIMING):
		input.actions.sort_custom(moves_priority_sort)
		return input.actions[0]
	else:
		return "ok"
