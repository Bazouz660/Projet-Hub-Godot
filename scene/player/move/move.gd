extends Node
class_name Move

# all-move variables here
var player : Player

# unique fields to redefine
@export var move_name : String
@export_group("Parameters")
@export var affected_by_gravity : bool = true
@export var stamina_required: float = 0.0
@export_group("Animation")
@export var animation : String
@export var backend_animation : String
@export var reverse_animation : bool = false
@export_group("Audio")
@export var sound : MoveSound

# general fields for internal usage
@onready var combos : Array[Combo] 

var enter_state_time : float

var has_queued_move : bool = false
var queued_move : String = "none, drop error please"

var has_forced_move : bool = false
var forced_move : String = "none, drop error please"

var moves_data_repo : MovesDataRepository


static var moves_priority : Dictionary = {
	"idle" : 0,
	"rest" : 1,
	"rest_to_idle" : 1,
	"idle_to_rest" : 1,
	"run" : 2,
	"sprint" : 3,
	"roll" : 10,
	"emote": 99,
	"slash_1" : 100,
	"slash_2" : 101,
	"slash_3" : 102,
	"idle_swim" : 1000,
	"swim" : 1001,
	"staggered" : 10000
}


static func moves_priority_sort(a : String, b : String):
	return moves_priority[a] > moves_priority[b]

# There is a wall of text as a general guide on this function in the end of the page, 
# because I'm too lazy to write proper docs for a "tutorial" project
func check_relevance(input : InputPackage) -> String:
	if has_forced_move:
		has_forced_move = false
		return forced_move
	
	check_combos(input)
	var relevance = default_lifecycle(input)
	if relevance == move_name:
		return "ok"
	return relevance

func default_lifecycle(input : InputPackage) -> String:
	#can return idle, but I want this error to be thrown to make me-from-the-future's life easier
	return "implement default lyfecycle pepega " + animation
	
func check_combos(input : InputPackage):
	for combo : Combo in combos:
		if combo.is_triggered(input):
			has_queued_move = true
			queued_move = combo.triggered_move

func assign_combos():
	for child in get_children():
		if child is Combo:
			combos.append(child)
			child.move = self

func form_hit_data(weapon : Weapon) -> HitData:
	print("someone tries to get hit by default Move")
	return HitData.blank()

@rpc("any_peer", "call_remote", "reliable")
func react_on_hit(hit : HitData):
	if is_interruptable():
		has_forced_move = true
		forced_move = "staggered"

func react_on_parry(hit : HitData):
	has_forced_move = true
	forced_move = "parried"

func update(_input : InputPackage, _delta : float):
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

func works_longer_than(time : float) -> bool:
	return get_progress() >= time

func works_less_than(time : float) -> bool:
	return get_progress() < time

func works_between(start : float, finish : float) -> bool:
	var progress = get_progress()
	return progress >= start and progress <= finish
	
func is_vulnerable() -> bool:
	return moves_data_repo.get_vulnerable(backend_animation, get_progress())

func is_interruptable() -> bool:
	return moves_data_repo.get_interruptable(backend_animation, get_progress())

func is_parryable() -> bool:
	return moves_data_repo.get_parryable(backend_animation, get_progress())
