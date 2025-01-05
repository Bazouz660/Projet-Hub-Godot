extends Node
class_name HumanoidStates


@export var humanoid: CharacterBody3D
@export var animator: SplitAnimator
@export var resources: HumanoidResources
@export var combat: HumanoidCombat
@export var moves_data_repo: MovesDataRepository
@export var sound_manager: HumanoidSoundManager


var moves: Dictionary # { string : Move }, where string is Move heirs name


func accept_moves():
	for child in get_children():
		if child is Move:
			moves[child.move_name] = child
			child.humanoid = humanoid
			child.animator = animator
			child.resources = resources
			child.combat = combat
			child.sound_manager = sound_manager
			child.moves_data_repo = moves_data_repo
			child.container = self
			child.DURATION = moves_data_repo.get_duration(child.backend_animation)
			child.assign_combos()


func moves_priority_sort(a: String, b: String):
	if moves[a].priority > moves[b].priority:
		return true
	else:
		return false

func get_move_by_name(move_name: String) -> Move:
	return moves[move_name]
