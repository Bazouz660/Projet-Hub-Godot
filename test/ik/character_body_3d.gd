extends CharacterBody3D

@onready var camera_pivot = $Camera/PreventRotationCopy/CameraPivot
@onready var animation_player = $AnimationPlayer
@onready var skeleton = %GeneralSkeleton

@export var use_root_motion = true
@export var animation: String = "ready_idle"
@export var walk_speed: float = 2.0
@export var run_speed: float = 5.0
@export var sprint_speed: float = 7.0

var SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 10.0

var current_rotation: Quaternion

func _ready():
	animation_player.play(animation)

func _get_root_motion_velocity(delta: float):
	var new_velocity: Vector3 = current_rotation * animation_player.get_root_motion_position() / delta * 2
	return new_velocity

func _get_velocity(direction: Vector3):
	var new_velocity = velocity
	if direction:
		new_velocity.x = direction.x * SPEED
		new_velocity.z = direction.z * SPEED
	else:
		new_velocity.x = move_toward(velocity.x, 0, SPEED)
		new_velocity.z = move_toward(velocity.z, 0, SPEED)
	return new_velocity

func _physics_process(delta):

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("roll") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")

	if input_dir == Vector2.ZERO:
		switch_animation("ready_idle")
		velocity.x = 0
		velocity.z = 0
		SPEED = 0
	elif Input.is_action_pressed("walk"):
		switch_animation("walk")
		SPEED = walk_speed
	elif Input.is_action_pressed("sprint"):
		switch_animation("sprint")
		SPEED = sprint_speed
	else:
		switch_animation("run")
		SPEED = run_speed

	var direction = (Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, camera_pivot.rotation.y)

	current_rotation = get_quaternion()


	var new_velocity
	if use_root_motion:
		new_velocity = _get_root_motion_velocity(delta)
	else:
		new_velocity = _get_velocity(direction)

	velocity.x = new_velocity.x
	velocity.z = new_velocity.z


	# Rotate toward the movement direction smoothly
	if direction.length() > 0.1:
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation + deg_to_rad(180), delta * ROTATION_SPEED)

	move_and_slide()

func _input(_event: InputEvent):
	# if control key is pressed, enable mouse capture
	if Input.is_action_pressed("show_mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		SceneManager.disable_player_input = true
	else:
		SceneManager.disable_player_input = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func switch_animation(anim: String):
	if animation == anim:
		return
	animation = anim
	animation_player.play(animation)
