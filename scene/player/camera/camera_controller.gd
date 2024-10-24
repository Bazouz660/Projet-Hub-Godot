extends Node3D

@export var horizontal_sensitivity: float = 0.01

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _process(delta):
	if Input.is_action_pressed("cam_left"):
		rotation.y += horizontal_sensitivity * 100 * delta
	if Input.is_action_pressed("cam_right"):
		rotation.y -= horizontal_sensitivity * 100 * delta

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * horizontal_sensitivity
