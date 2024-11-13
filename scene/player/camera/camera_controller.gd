extends Node3D

@export var horizontal_sensitivity: float = 0.01
@export var position_damping_scale: float = 0.5
@export var rotation_damping_scale: float = 0.5

@onready var target = $"../Target"

var target_rotation: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	target_rotation = rotation.y
	
func _process(delta):
	if SceneManager.disable_player_input:
		return
	
	# Handle keyboard input
	if Input.is_action_pressed("cam_left"):
		target_rotation = rotation.y + horizontal_sensitivity * 100 * delta
	if Input.is_action_pressed("cam_right"):
		target_rotation = rotation.y - horizontal_sensitivity * 100 * delta
	
	# Smooth rotation with damping.
	rotation.y = target_rotation

func _physics_process(delta):
	global_position = lerp(global_position, target.global_position, pow(delta, position_damping_scale))

func _unhandled_input(event):
	if SceneManager.disable_player_input:
		return
	
	if event is InputEventMouseMotion:
		target_rotation = rotation.y - event.relative.x * horizontal_sensitivity
