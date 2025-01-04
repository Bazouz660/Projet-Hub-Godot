extends Node
class_name LegsBehaviour

var model: HumanoidModel
var moves_container: HumanoidStates
var legs_manager: Legs
var current_legs_move: Move
var last_target_move: String = ""

func on_enter():
	last_target_move = ""
	model.animator.update_legs_animation()

func update(input: InputPackage, delta: float):
	transition_legs_state(input, delta)
	current_legs_move._update(input, delta)

func on_exit():
	current_legs_move.on_exit_state()

func transition_legs_state(_input: InputPackage, _delta: float):
	pass

@rpc("any_peer", "call_local", "reliable")
func _change_state(next_state: String):
	print("Changing state to: ", next_state)
	current_legs_move = moves_container.get_move_by_name(next_state)
	legs_manager.current_legs_move = current_legs_move
	model.animator.update_legs_animation()
	last_target_move = next_state

func change_state(next_state: String):
	if last_target_move == next_state:
		return
	_change_state.rpc(next_state)
