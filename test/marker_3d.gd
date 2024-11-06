extends Node3D

@export var horizontal_sensitivity: float = 0.0001
@onready var character_body_3d = $".."

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _process(delta):
	if Input.is_action_pressed("cam_left"):
		character_body_3d.rotation.y += horizontal_sensitivity * 100 * delta
	if Input.is_action_pressed("cam_right"):
		character_body_3d.rotation.y -= horizontal_sensitivity * 100 * delta

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		character_body_3d.rotation.y -= event.relative.x * horizontal_sensitivity
