extends Node

var _sound_queues_by_name : Dictionary
var _sound_pools_by_name : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#_sound_queues_by_name.get_or_add("FireBallSoundQueue", get_node("FireBallSoundQueue") as SoundQueue)

#func playFireBallSound():
	#_sound_queues_by_name["FireBallSoundQueue"].play_sound()
