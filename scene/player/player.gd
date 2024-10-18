extends CharacterBody3D

class_name Player

@onready var camera_3d = $CameraPivot/Camera3D
@onready var step_cast = $StepCast
@onready var camera_pivot = $CameraPivot

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const STEP_INTERPOLATION_SPEED = 20.0

var yaw = 0.0;
var pitch = 0.0;
var sensitivity = 0.003;

var grounded = false;

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	camera_3d.current = is_multiplayer_authority()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;

func handle_input(_delta: float):
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_grounded():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, yaw)
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func _physics_process(delta: float) -> void:
	# Add gravity.
	if not is_grounded():
		velocity += get_gravity() * delta
		
	if is_multiplayer_authority() and not Global.game_manager.disable_player_input:
		handle_input(delta)

	move(delta)
	
func move(delta: float):
	var query = PhysicsShapeQueryParameters3D.new()
	query.exclude = [self]
	query.shape = step_cast.shape
	query.transform = step_cast.global_transform
	var result = get_world_3d().direct_space_state.intersect_shape(query, 1)
	if !result:
		step_cast.force_shapecast_update()
	
	if step_cast.is_colliding() and absf(velocity.y) <= 0.0001 and !result:
		var collision_point = step_cast.get_collision_point(0)
		global_position.y = lerp(global_position.y, collision_point.y, delta * STEP_INTERPOLATION_SPEED)
		velocity.y = 0.0
		grounded = true
	else:
		grounded = false
	
	RenderingServer.global_shader_parameter_set("player_position", global_position)
	move_and_slide()

func _input(event):
	if Global.game_manager.disable_player_input:
		return
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * sensitivity
		yaw = wrap(yaw, 0.0, deg_to_rad(360))
		camera_pivot.global_rotation = Vector3(deg_to_rad(-35), yaw, 0.0)
		
func is_grounded() -> bool:
	return grounded or is_on_floor()
