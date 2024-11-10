extends Node3D
class_name SoundManager3D

var _sounds : Dictionary
var _counters : Dictionary
@onready var step_sound_pool = $StepSoundPool
@onready var player = $"../.." as Player

# Called when the node enters the scene tree for the first time.
func _ready():
	_add_sound("step", "StepSoundPool")
	_add_sound("roll", "RollSoundPool")
	_add_sound("swipe_1", "SwipeQueue")
	_add_sound("swipe_2", "SwipeQueue2")
	_add_sound("swipe_3", "SwipeQueue3")

func _add_sound(sound_name : String, node_name : String):
	_sounds.get_or_add(sound_name, get_node(node_name))
	_counters.get_or_add(sound_name, 0.0)

@rpc("any_peer", "call_local")
func _rpc_play_sound(sound_name : String):
	if _sounds.get(sound_name) is SoundPool3D:
		_sounds.get(sound_name).play_random_sound()
	elif _sounds.get(sound_name) is SoundQueue3D:
		_sounds.get(sound_name).play_sound()

func play_sound(sound_name : String, delay : float = 0.0):	
	if delay == 0:
		rpc.call("_rpc_play_sound", sound_name)
	else:
		var timer = Timer.new()
		timer.autostart = true
		timer.one_shot = true
		timer.wait_time = delay
		timer.timeout.connect(func():
			rpc.call("_rpc_play_sound", sound_name)
			timer.queue_free())
		add_child(timer)

func play_sound_with_interval(sound_name : String, interval : float, delta : float):
	if _counters[sound_name] >= interval:
		_counters[sound_name] = 0
		rpc.call("_rpc_play_sound", sound_name)
	else:
		_counters[sound_name] += delta
