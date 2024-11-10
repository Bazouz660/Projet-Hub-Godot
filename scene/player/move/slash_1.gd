extends Move
class_name Slash1

@export var TRANSITION_TIMING = 1.6 # Full animation duration
@export var COMBO_TIMING = 1.1 # Time at which we can chain the attack

func on_enter_state():
	player.velocity = Vector3.ZERO
	player.stamina.use_stamina(stamina_required)

func check_relevance(input : InputPackage):
	check_combos(input)
	if works_longer_than(COMBO_TIMING) and has_queued_move:
		has_queued_move = false
		return queued_move
	elif works_longer_than(TRANSITION_TIMING):
		input.actions.sort_custom(moves_priority_sort)
		return input.actions[0]
	else:
		return "ok"
