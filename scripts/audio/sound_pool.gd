@tool
extends Node
class_name SoundPool

var sounds : Array[SoundQueue]
var random : RandomNumberGenerator = RandomNumberGenerator.new()
var last_index : int = -1

func _ready():
	for child in get_children():
		if child is SoundQueue:
			sounds.append(child as SoundQueue)

func play_random_sound(never_play_twice : bool = true):
	var index = random.randi_range(0, sounds.size() - 1)

	if never_play_twice:
		while index == last_index:
			index = random.randi_range(0, sounds.size() - 1)
		last_index = index

	sounds[index].play_sound()

func _get_configuration_warnings():
	var number_of_sound_queue_children = 0
	for child in get_children():
		if child is SoundQueue:
			number_of_sound_queue_children += 1
	
	if number_of_sound_queue_children < 2:
		return "Expected two or more children of type SoundQueue."
