extends Move
class_name TorsoPartialMove

@export var legs_behaviour: LegsBehaviour

func process_input_vector(input: InputPackage, delta: float):
	legs_behaviour.current_legs_move.process_input_vector(input, delta)

func _update(input: InputPackage, delta: float):
	legs_behaviour.update(input, delta)
	super._update(input, delta)


# IF YOU WANT TO OVERRIDE THESE METHODS, MAKE SURE TO CALL SUPER
func on_enter_state():
	print("Entering torso move")
	legs_behaviour.on_enter()

# IF YOU WANT TO OVERRIDE THESE METHODS, MAKE SURE TO CALL SUPER
func on_exit_state():
	print("Exiting torso move")
	legs_behaviour.on_exit()
	animator.clear_torso_animation()
