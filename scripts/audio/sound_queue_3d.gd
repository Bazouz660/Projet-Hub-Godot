@tool
extends Node3D
class_name SoundQueue3D

@export var count : int = 1 

var next : int = 0
var audio_stream_players : Array[AudioStreamPlayer3D]

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_child_count() ==  0:
		print("No AudiStreamPlayer3D child found")
		return
	
	var child = get_child(0)
	if child is AudioStreamPlayer3D:
		var audio_stream_player = child as AudioStreamPlayer3D
		audio_stream_players.append(audio_stream_player)
		
		for i in count:
			var varduplicate = audio_stream_player.duplicate()
			add_child(varduplicate)
			audio_stream_players.append(varduplicate)

func _get_configuration_warnings():
	if get_child_count() == 0:
		return "No children found. Expected one AudioStreamPlayer3D child."
	if get_child(0) is not AudioStreamPlayer3D:
		return "Expected first child to be an AudioStreamPlayer3D."

func play():
	if !audio_stream_players[next].playing:
		audio_stream_players[next].play()
		next += 1
		next %= audio_stream_players.size()
