@tool
extends Node3D
class_name SoundPool3D

var sounds : Array[SoundQueue3D]
var random : RandomNumberGenerator = RandomNumberGenerator.new()
var last_index : int = -1

func _ready():
	for child in get_children():
		if child is SoundQueue3D:
			sounds.append(child as SoundQueue3D)

func play_random_sound(never_play_twice : bool = true):
	if sounds.size() == 1:
		sounds[0].play_sound()
		return
	
	var index = random.randi_range(0, sounds.size() - 1)

	if never_play_twice:
		while index == last_index:
			index = random.randi_range(0, sounds.size() - 1)
		last_index = index

	sounds[index].play_sound()

func _get_configuration_warnings():
	var number_of_sound_queue_children = 0
	for child in get_children():
		if child is SoundQueue3D:
			number_of_sound_queue_children += 1
	
	if number_of_sound_queue_children < 2:
		return "Expected two or more children of type SoundQueue3D."
