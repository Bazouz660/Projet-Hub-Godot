extends Node3D
class_name SoundPlayer3D

var _sounds: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	_add_sound("step_grass", "StepGrassSoundPool")
	_add_sound("step_rock", "StepRockSoundPool")
	_add_sound("step_sand", "StepSandSoundPool")
	_add_sound("step_water", "StepWaterSoundPool")
	_add_sound("swim", "SwimSoundPool")
	_add_sound("swim_thread", "SwimThreadingSoundPool")
	_add_sound("roll", "RollSoundPool")
	_add_sound("swipe_1", "SwipeQueue")
	_add_sound("swipe_2", "SwipeQueue2")
	_add_sound("swipe_3", "SwipeQueue3")
	_add_sound("heal_potion", "HealPotionQueue")

func _add_sound(sound_name: String, node_name: String):
	_sounds.get_or_add(sound_name, get_node(node_name))

func play(sound_name: String):
	if _sounds.has(sound_name):
		_sounds[sound_name].play()
