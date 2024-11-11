extends Node
class_name HumanoidSoundManager

var _sounds : Array = []
var _counters : Dictionary
var sound_player : SoundPlayer3D
@onready var model := $".." as HumanoidModel

func _ready():
	_add_sound_key("step")
	_add_sound_key("roll")
	_add_sound_key("swipe_1")
	_add_sound_key("swipe_2")
	_add_sound_key("swipe_3")

func _add_sound_key(sound_name : String):
	_sounds.append(sound_name)
	_counters.get_or_add(sound_name, 0.0)

@rpc("any_peer", "call_local")
func _rpc_play_sound(sound_name : String):	
	sound_player.play(sound_name)
	
func _get_material_sound(sound_name : String) -> String:
	var material := model.player.material_detector.check_material() as Dictionary

	# If no material is found, add a default material type
	if material.is_empty():
		material.get_or_add("type", "grass")

	var material_type = material["type"]
	if material_type != "Unknown":
		sound_name += "_" + material_type
	return sound_name
	
func _play_sound_internal(sound_name : String, material_based : bool):
	if material_based:
		sound_name = _get_material_sound(sound_name)
	rpc.call("_rpc_play_sound", sound_name)
		
func update(sound : MoveSound, delta : float):
	if !is_instance_valid(sound):
		return
	if sound.sound_name != "" and !sound.play_once:
		if _counters[sound.sound_name] >= sound.delay:
			_counters[sound.sound_name] = 0
			_play_sound_internal(sound.sound_name, sound.material_based)
		else:
			_counters[sound.sound_name] += delta

func update_once(sound : MoveSound):
	if !is_instance_valid(sound):
		return
	if sound.sound_name != "" and sound.play_once:
		if sound.delay == 0:
			_play_sound_internal(sound.sound_name, sound.material_based)
		else:
			var timer = Timer.new()
			timer.autostart = true
			timer.one_shot = true
			timer.wait_time = sound.delay
			timer.timeout.connect(func():
				_play_sound_internal(sound.sound_name, sound.material_based)
				timer.queue_free())
			add_child(timer)
