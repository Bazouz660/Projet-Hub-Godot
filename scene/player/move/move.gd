extends Node
class_name Move

# all-move variables here
var player: Player
var resources: HumanoidResources

# unique fields to redefine
@export var move_name: String
@export_group("Parameters")
@export var affected_by_gravity: bool = true
@export var stamina_cost: float = 0.0
@export var TRANSITION_TIMING: float = 0.0
@export_group("Animation")
@export var animation: String
@export var backend_animation: String
@export var reverse_animation: bool = false
@export_group("Audio")
@export var sound: MoveSound

# general fields for internal usage
@onready var combos: Array[Combo]


var enter_state_time: float

var has_queued_move: bool = false
var queued_move: String = "none, drop error please"

var has_forced_move: bool = false
var forced_move: String = "none, drop error please"

var moves_data_repo: MovesDataRepository


static var moves_priority: Dictionary = {
	"idle": 0,
	"rest": 1,
	"rest_to_idle": 1,
	"idle_to_rest": 1,
	"run": 2,
	"sprint": 3,
	"roll": 10,
	"emote": 99,
	"slash_1": 100,
	"slash_2": 101,
	"slash_3": 102,
	"idle_swim": 1000,
	"swim": 1001,
	"staggered": 10000
}


static func moves_priority_sort(a: String, b: String):
	return moves_priority[a] > moves_priority[b]

func check_relevance(input: InputPackage) -> String:
	if has_forced_move:
		has_forced_move = false
		return forced_move

	check_combos(input)
	var relevance = default_lifecycle(input)
	if relevance == move_name:
		return "ok"
	return relevance

func default_lifecycle(_input: InputPackage) -> String:
	if works_longer_than(TRANSITION_TIMING):
		return best_input_that_can_be_paid(_input)
	return "ok"

func check_combos(input: InputPackage):
	for combo: Combo in combos:
		if combo.is_triggered(input) and resources.can_be_paid(player.model.moves[combo.triggered_move]):
			has_queued_move = true
			queued_move = combo.triggered_move

func best_input_that_can_be_paid(input: InputPackage) -> String:
	input.actions.sort_custom(moves_priority_sort)
	for action in input.actions:
		if resources.can_be_paid(player.model.moves[action]):
			if player.model.moves[action] == self:
				return "ok"
			return action
	return "throwing error because for some reason input.actions doesn't contain even idle"

func assign_combos():
	for child in get_children():
		if child is Combo:
			combos.append(child)
			child.move = self

func form_hit_data(_weapon: Weapon) -> HitData:
	print("someone tries to get hit by default Move")
	return HitData.blank()

func react_on_hit(hit: HitData):
	if is_vulnerable():
		resources.lose_health(hit.damage)
		print("I'm hit by ", hit.weapon, " for ", hit.damage, " damage")
		print("I have ", resources.health, " health left")
	if is_interruptable():
		try_force_move.rpc("staggered")

@rpc("any_peer", "call_remote", "reliable")
func try_force_move(move: String):
	has_forced_move = true
	forced_move = move

func react_on_parry(_hit: HitData):
	try_force_move("parry")

func update_resources(delta: float):
	resources.update(delta)

func update(_input: InputPackage, _delta: float):
	pass

func on_enter_state():
	pass

func on_exit_state():
	pass

func mark_enter_state():
	enter_state_time = Time.get_unix_time_from_system()

func get_progress() -> float:
	var now = Time.get_unix_time_from_system()
	return now - enter_state_time

func works_longer_than(time: float) -> bool:
	return get_progress() >= time

func works_less_than(time: float) -> bool:
	return get_progress() < time

func works_between(start: float, finish: float) -> bool:
	var progress = get_progress()
	return progress >= start and progress <= finish
	
func is_vulnerable() -> bool:
	return moves_data_repo.get_vulnerable(backend_animation, get_progress())

func is_interruptable() -> bool:
	return moves_data_repo.get_interruptable(backend_animation, get_progress())

func is_parryable() -> bool:
	return moves_data_repo.get_parryable(backend_animation, get_progress())
