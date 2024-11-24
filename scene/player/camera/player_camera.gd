extends Node3D
class_name PlayerCamera

@onready var player := $".."
@onready var pivot : Marker3D = $PreventRotationCopy/CameraPivot
@onready var actual_camera : Camera3D = $PreventRotationCopy/CameraPivot/Camera3D
@onready var audio_listener_3d : AudioListener3D = $PreventRotationCopy/CameraPivot/AudioListener3D

func _ready():	
	player.ready.connect(func():
		if player is Dummy:
			return
		if player.is_multiplayer_authority():
			audio_listener_3d.make_current())

func get_pivot() -> Marker3D:
	return pivot

func get_actual_camera() -> Camera3D:
	return actual_camera
