extends Node3D

@export var horizontal_sensitivity: float = 0.01
@export var position_damping_scale: float = 0.5
@export var rotation_damping_scale: float = 0.5
@export var enable_vertical_rotation: bool = true
@export var enable_zoom: bool = true
@export var invert_vertical_rotation: bool = false
@export var invert_horizontal_rotation: bool = false

@onready var target = $"../Target"
@onready var actual_camera = $Camera3D

var target_rotation: Vector2 = Vector2.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	target_rotation.y = rotation.y

func _process(delta):
	if SceneManager.disable_player_input:
		return

	# Handle keyboard input
	if Input.is_action_pressed("cam_left"):
		target_rotation.y = rotation.y + horizontal_sensitivity * 100 * delta
	if Input.is_action_pressed("cam_right"):
		target_rotation.y = rotation.y - horizontal_sensitivity * 100 * delta

	# Smooth rotation with damping.
	rotation.y = target_rotation.y

	if enable_vertical_rotation:
		rotation.x = target_rotation.x

func _physics_process(delta):
	global_position = lerp(global_position, target.global_position, pow(delta, position_damping_scale))

func _unhandled_input(event):
	if SceneManager.disable_player_input:
		return

	if event is InputEventMouseMotion:
		if invert_horizontal_rotation:
			target_rotation.y = rotation.y + event.relative.x * horizontal_sensitivity
		else:
			target_rotation.y = rotation.y - event.relative.x * horizontal_sensitivity
		if enable_vertical_rotation:
			if invert_vertical_rotation:
				target_rotation.x = clamp(target_rotation.x - event.relative.y * horizontal_sensitivity, -PI / 2, PI / 2)
			else:
				target_rotation.x = clamp(target_rotation.x + event.relative.y * horizontal_sensitivity, -PI / 2, PI / 2)

	if enable_zoom:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			actual_camera.position.z = max(0.1, actual_camera.position.z - 0.1)
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			actual_camera.position.z = min(100, actual_camera.position.z + 0.1)
