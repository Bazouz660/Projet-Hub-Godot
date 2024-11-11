@tool
extends Node3D
class_name SoundPool3D

@export var audio_streams : Array[AudioStream] = []
@export var attenuation_mode : AudioStreamPlayer3D.AttenuationModel = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
@export_range(-80.0, 80.0) var volume_db : float = 0.0
@export_range(0.1, 100.0) var unit_size : float = 10.0
@export_range(-24.0, 6.0) var max_db : float = 3.0
@export_range(0.01, 100) var pitch_scale : float = 1.0
@export_range(0, 4096) var max_distance : float = 20.0

var _queues : Array[SoundQueue3D]
var random : RandomNumberGenerator = RandomNumberGenerator.new()
var last_index : int = -1

func _ready():
	for stream in audio_streams:
		var sound_queue = SoundQueue3D.new()
		var audio_stream_player = AudioStreamPlayer3D.new()
		audio_stream_player.stream = stream
		audio_stream_player.volume_db = volume_db
		audio_stream_player.unit_size = unit_size
		audio_stream_player.max_db = max_db
		audio_stream_player.pitch_scale = pitch_scale
		audio_stream_player.max_distance = max_distance
		
		sound_queue.add_child(audio_stream_player)
		add_child(sound_queue)
		_queues.append(sound_queue)

func play(never_play_twice : bool = true):
	if _queues.size() == 1:
		_queues[0].play()
		return
	
	var index = random.randi_range(0, _queues.size() - 1)

	if never_play_twice:
		while index == last_index:
			index = random.randi_range(0, _queues.size() - 1)
		last_index = index

	_queues[index].play()

func _get_configuration_warnings():
	var number_of_sound_queue_children = 0
	for child in get_children():
		if child is SoundQueue3D:
			number_of_sound_queue_children += 1
	
	if number_of_sound_queue_children < 2:
		return "Expected two or more children of type SoundQueue3D."
