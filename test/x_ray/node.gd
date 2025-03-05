extends Node3D
class_name XRayManager

@export var subviewport_container: SubViewportContainer
@export var player: Node3D
@export var camera: Camera3D

@export_range(0.01, 0.5) var radius: float = 0.15
@export_range(0.001, 0.05) var edge_softness: float = 0.02
@export_range(0.001, 0.02) var outline_thickness: float = 0.005
@export var outline_color: Color = Color.WHITE
@export var use_hexagon: bool = true
@export_range(0.0, 1.0) var darkness_amount: float = 0.6

@export var auto_enable: bool = true
@export_range(1.0, 200.0) var ray_length: float = 100.0
@export var debug_mode: bool = false # Enable to show debug info

var material: ShaderMaterial
var player_is_obscured: bool = false

func _ready():
	# Verify we have all required nodes
	if not subviewport_container or not player or not camera:
		push_error("XRayManager: Missing required node references")
		return

	# Get or create the shader material
	if subviewport_container.material:
		material = subviewport_container.material as ShaderMaterial
	else:
		# Create the shader resource directly
		var shader = load("res://xray_shader.gdshader")
		if not shader:
			push_error("XRayManager: Failed to load shader")
			return

		material = ShaderMaterial.new()
		material.shader = shader
		subviewport_container.material = material

	# Initialize shader parameters
	_update_shader_parameters()

func _process(delta):
	if not material or not player or not camera:
		return

	# Update player position in screen space
	var player_screen_pos = _get_player_screen_position()
	material.set_shader_parameter("player_position", player_screen_pos)

	# Check if player is obscured
	if auto_enable:
		player_is_obscured = _is_player_obscured()
		material.set_shader_parameter("darkness_amount", 0.6 if player_is_obscured else 0.0)

	# Debug
	if debug_mode:
		print("Player screen position: ", player_screen_pos)
		print("Player is obscured: ", player_is_obscured)

func _update_shader_parameters():
	if not material:
		return

	material.set_shader_parameter("radius", radius)
	material.set_shader_parameter("edge_softness", edge_softness)
	material.set_shader_parameter("outline_thickness", outline_thickness)
	material.set_shader_parameter("outline_color", outline_color)
	material.set_shader_parameter("use_hexagon", use_hexagon)
	material.set_shader_parameter("darkness_amount", darkness_amount)

func _get_player_screen_position() -> Vector2:
	var viewport = get_viewport()
	if not viewport:
		return Vector2(0.5, 0.5)

	# Project player position to screen space
	var screen_pos = camera.unproject_position(player.global_position)

	# Convert to normalized coordinates (0-1) for the shader
	var normalized_pos = Vector2(
		screen_pos.x / viewport.size.x,
		screen_pos.y / viewport.size.y
	)

	return normalized_pos

func _is_player_obscured() -> bool:
	# Perform a raycast from camera to player
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return false

	var ray_origin = camera.global_position
	var ray_target = player.global_position

	var params = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
	params.exclude = [player]
	params.collision_mask = 1 # Use your collision layer

	var result = space_state.intersect_ray(params)

	# If we hit something, the player is obscured
	return !result.is_empty()

# Called when shader parameters change in the inspector
func _on_parameter_changed():
	_update_shader_parameters()

# Property setters to update shader when properties change
func set_radius(value):
	radius = value
	_update_shader_parameters()

func set_edge_softness(value):
	edge_softness = value
	_update_shader_parameters()

func set_outline_thickness(value):
	outline_thickness = value
	_update_shader_parameters()

func set_outline_color(value):
	outline_color = value
	_update_shader_parameters()

func set_use_hexagon(value):
	use_hexagon = value
	_update_shader_parameters()

func set_darkness_amount(value):
	darkness_amount = value
	_update_shader_parameters()
