extends CharacterBody3D
class_name FreeCam

@export var BASE_SPEED = 5.0
@export var CAMERA_SENSIVITY = 100.0
@onready var camera := $Camera3D as Camera3D

var speed = BASE_SPEED

func _ready():
	#get_viewport().debug_draw = Viewport.DebugDraw.DEBUG_DRAW_WIREFRAME
	pass

func disable():
	hide()
	set_physics_process(false)
	set_process_input(false)
	camera.current = false

func enable():
	show()
	set_physics_process(true)
	set_process_input(true)
	camera.current = true

func _input(event: InputEvent):
	if event is InputEventKey and event.keycode == KEY_0:
		print("Debug draw: ", get_viewport().debug_draw)
		get_viewport().debug_draw = Viewport.DebugDraw.DEBUG_DRAW_WIREFRAME
	elif event is InputEventKey and event.keycode == KEY_9:
		get_viewport().debug_draw = Viewport.DebugDraw.DEBUG_DRAW_DISABLED

	if Input.is_key_label_pressed(KEY_SHIFT):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			BASE_SPEED = clamp(BASE_SPEED + 1, 1, 100)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			BASE_SPEED = clamp(BASE_SPEED - 1, 1, 100)

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rotation = get_rotation_degrees()
		rotation.x -= event.relative.y * CAMERA_SENSIVITY * get_process_delta_time()
		rotation.y -= event.relative.x * CAMERA_SENSIVITY * get_process_delta_time()
		rotation.x = clamp(rotation.x, -90, 90)
		set_rotation_degrees(rotation)


func _physics_process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# get the relative mouse motion
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.is_key_label_pressed(KEY_SHIFT):
		speed = BASE_SPEED * 2
	else:
		speed = BASE_SPEED

	velocity = Vector3.ZERO

	var direction = Vector3.ZERO
	if Input.is_key_label_pressed(KEY_Z):
		direction.z -= 1
	if Input.is_key_label_pressed(KEY_S):
		direction.z += 1
	if Input.is_key_label_pressed(KEY_Q):
		direction.x -= 1
	if Input.is_key_label_pressed(KEY_D):
		direction.x += 1

	velocity = transform.basis * direction.normalized() * speed

	if Input.is_key_label_pressed(KEY_SPACE):
		velocity.y = speed
	if Input.is_key_label_pressed(KEY_CTRL):
		velocity.y = - speed

	move_and_slide()
