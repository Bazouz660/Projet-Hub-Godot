@tool
extends Node
class_name SoundQueue

@export var count : int = 1 

var next : int = 0
var audio_stream_players : Array[AudioStreamPlayer]

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_child_count() ==  0:
		print("No AudiStreamPlayer child found")
		return
	
	var child = get_child(0)
	if child is AudioStreamPlayer:
		var audio_stream_player = child as AudioStreamPlayer
		audio_stream_players.append(audio_stream_player)
		
		for i in count:
			var varduplicate = audio_stream_player.duplicate()
			add_child(varduplicate)
			audio_stream_players.append(varduplicate)

func _get_configuration_warnings():
	if get_child_count() == 0:
		return "No children found. Expected one AudioStreamPlayer child."
	if get_child(0) is not AudioStreamPlayer:
		return "Expected first child to be an AudioStreamPlayer."

func play_sound():
	if !audio_stream_players[next].playing:
		audio_stream_players[next].pitch_scale = randf_range(0.95, 1.1)
		audio_stream_players[next].play()
		next += 1
		next %= audio_stream_players.size()
