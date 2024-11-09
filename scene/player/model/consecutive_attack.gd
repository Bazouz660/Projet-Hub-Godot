extends Combo
class_name ConsecutiveAttack

@export var root_move : Move

@export var panic_click_prevention : float = 0.1

@export var primary_input : String
@export var next_attack : String

func _ready():
	triggered_move = next_attack

func is_triggered(input : InputPackage):
	return input.actions.has(primary_input) and root_move.works_longer_than(panic_click_prevention)
