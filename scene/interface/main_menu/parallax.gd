@tool
extends Control

@onready var sky = $Sky as TextureRect
@onready var cloud = $Cloud as TextureRect
@onready var tree_far = $TreeFar as TextureRect
@onready var tree_close = $TreeClose as TextureRect

var cloud_speed = 0.05
var tree_far_speed = 0.07
var tree_close_speed = 0.1

var current_cloud_offset = Vector2.ZERO
var current_tree_far_offset = Vector2.ZERO
var current_tree_close_offset = Vector2.ZERO

var sensitivity = 0.005
var damping = 3.0

# Initialize the offset based on the initial mouse position
func _ready():
	var mouse_pos = get_local_mouse_position()
	var center = get_viewport().size / 2.0
	var initial_offset = (mouse_pos - center) * sensitivity

	# Set initial offsets
	current_cloud_offset.x = initial_offset.x * cloud_speed
	current_tree_far_offset.x = initial_offset.x * tree_far_speed
	current_tree_close_offset.x = initial_offset.x * tree_close_speed

	# Apply initial offset to shader parameters
	apply_offsets()

func apply_offsets():
	(cloud.material as ShaderMaterial).set_shader_parameter("x_offset", current_cloud_offset.x)
	(tree_far.material as ShaderMaterial).set_shader_parameter("x_offset", current_tree_far_offset.x)
	(tree_close.material as ShaderMaterial).set_shader_parameter("x_offset", current_tree_close_offset.x)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var mouse_pos = get_local_mouse_position()
	var center = get_viewport().size / 2.0
	var target_offset = (mouse_pos - center) * sensitivity

	current_cloud_offset.x = lerp(current_cloud_offset.x, target_offset.x * cloud_speed, delta * damping)
	current_tree_far_offset.x = lerp(current_tree_far_offset.x, target_offset.x * tree_far_speed, delta * damping)
	current_tree_close_offset.x = lerp(current_tree_close_offset.x, target_offset.x * tree_close_speed, delta * damping)

	apply_offsets()
