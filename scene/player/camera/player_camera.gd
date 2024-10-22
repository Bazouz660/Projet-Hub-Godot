extends Node3D
class_name PlayerCamera

@onready var pivot : Marker3D = $PreventRotationCopy/CameraPivot
@onready var actual_camera : Camera3D = $PreventRotationCopy/CameraPivot/Camera3D

func get_pivot() -> Marker3D:
	return pivot

func get_actual_camera() -> Camera3D:
	return actual_camera
