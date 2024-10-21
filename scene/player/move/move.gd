extends Node
class_name Move


# all-move variables here
var player : CharacterBody3D

# unique fields to redefine
var animation : String
var move_name : String
var has_queued_move : bool = false
var queued_move : String = "none, drop error please"
var affected_by_gravity : bool = true

# general fields for internal usage
var enter_state_time : float


static var moves_priority : Dictionary = {
	"idle" : 1,
	"run" : 2,
	"sprint" : 3,
	"roll" : 10,
}


static func moves_priority_sort(a : String, b : String):
	if moves_priority[a] > moves_priority[b]:
		return true
	else:
		return false

# There is a wall of text as a general guide on this function in the end of the page, 
# because I'm too lazy to write proper docs for a "tutorial" project
func check_relevance(_input : InputPackage) -> String:
	print_debug("error, implement the check_relevance function on your state")
	return "error, implement the check_relevance function on your state"


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
	if get_progress() >= time:
		return true
	return false

func works_less_than(time : float) -> bool:
	if get_progress() < time: 
		return true
	return false

func works_between(start : float, finish : float) -> bool:
	var progress = get_progress()
	if progress >= start and progress <= finish:
		return true
	return false
