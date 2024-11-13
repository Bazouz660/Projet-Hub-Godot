extends Node
class_name HumanoidSoundManager

var _sounds : Array = []
var _counters : Dictionary
var _current_sound : String = ""
var sound_player : SoundPlayer3D
@onready var model := $".." as HumanoidModel

@rpc("any_peer", "call_local")
func _rpc_play_sound_local(sound_name : String):	
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
	
func _play_sound_internal(sound_name : String, material_based : bool, local : bool):
	if material_based:
		sound_name = _get_material_sound(sound_name)
		
	if local:
		rpc.call("_rpc_play_sound_local", sound_name)
	else:
		sound_player.play(sound_name)

func update(sound : MoveSound, delta : float):
	if !is_instance_valid(sound):
		return
	if sound.sound_name != "" and !sound.play_once:
		var counter = _counters.get_or_add(sound.sound_name, sound.delay)
		
		if _current_sound != sound.sound_name:
			_current_sound = sound.sound_name
			counter = sound.delay
		
		if counter >= sound.delay:
			_counters[sound.sound_name] = 0
			_play_sound_internal(sound.sound_name, sound.material_based, true)
		else:
			_counters[sound.sound_name] += delta

func update_once(sound : MoveSound):
	if !is_instance_valid(sound):
		return
	if sound.sound_name != "" and sound.play_once:
		if sound.delay == 0.0:
			_play_sound_internal(sound.sound_name, sound.material_based, false)
		else:
			var timer = Timer.new()
			timer.autostart = true
			timer.one_shot = true
			timer.wait_time = sound.delay
			timer.timeout.connect(func():
				_play_sound_internal(sound.sound_name, sound.material_based, false)
				timer.queue_free())
			add_child(timer)
