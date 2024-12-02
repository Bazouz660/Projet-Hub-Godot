extends Node
class_name LegsBehaviour

var model: HumanoidModel
var moves_container: HumanoidStates
var legs_manager: Legs
var current_legs_move: Move

func on_enter():
	model.animator.update_legs_animation()

func update(input: InputPackage, delta: float):
	transition_legs_state(input, delta)
	current_legs_move._update(input, delta)

func transition_legs_state(_input: InputPackage, _delta: float):
	pass

func change_state(next_state: String):
	print("Changing state to: ", next_state)
	current_legs_move = moves_container.get_move_by_name(next_state)
	legs_manager.current_legs_move = current_legs_move
	model.animator.update_legs_animation()
