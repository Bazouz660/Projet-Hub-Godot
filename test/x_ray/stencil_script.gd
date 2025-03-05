extends Node3D

@export var player: Node3D
@export var camera: Camera3D
@export var radius: float = 5.0
@export var use_hexagon: bool = true
@export var transparency: float = 0.3
@export var outline_enabled: bool = true
@export var outline_color: Color = Color.WHITE
@export var visual_debug: bool = false

# Store original materials and their occluding versions
var original_materials = {}
var transparent_materials = {}
var currently_occluding = []

# Visual indicators (optional)
var area_indicator: MeshInstance3D

func _ready():
	if not player or not camera:
		push_error("Player or camera reference missing")
		return

	# Create visual indicator if debugging is enabled
	if visual_debug:
		_create_debug_visuals()

func _physics_process(_delta):
	# Reset previously occluding objects
	for obj in currently_occluding:
		if obj is MeshInstance3D and original_materials.has(obj):
			obj.material_override = original_materials[obj]

	currently_occluding.clear()

	# Find objects between camera and player
	_update_occlusion()

	# Update debug visuals position
	if visual_debug and area_indicator:
		area_indicator.global_position = player.global_position

func _create_debug_visuals():
	# Create a visual indicator for the effect area
	area_indicator = MeshInstance3D.new()
	add_child(area_indicator)

	# Create mesh based on shape preference
	if use_hexagon:
		var cylinder = CylinderMesh.new()
		cylinder.radial_segments = 6 # Hexagon
		cylinder.height = 0.1 # Thin disk
		cylinder.top_radius = radius
		cylinder.bottom_radius = radius
		area_indicator.mesh = cylinder
	else:
		var cylinder = CylinderMesh.new()
		cylinder.radial_segments = 32 # Circle
		cylinder.height = 0.1
		cylinder.top_radius = radius
		cylinder.bottom_radius = radius
		area_indicator.mesh = cylinder

	# Create material for visualization
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.0, 0.0, 0.2) # Red semi-transparent
	area_indicator.material_override = material

	# Orient properly (assuming Y is up)
	area_indicator.rotation_degrees.x = 90

func _update_occlusion():
	# Get space for raycast
	var space_state = get_world_3d().direct_space_state

	# Cast ray from camera to player
	var ray_origin = camera.global_position
	var ray_target = player.global_position

	# Create query parameters
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
	query.exclude = [player] # Don't hit the player

	# Perform raycast
	var result = space_state.intersect_ray(query)
	while not result.is_empty():
		var collider = result.collider
		if collider is Node3D:
			# Check if inside radius
			var dist_to_player = Vector2(
				collider.global_position.x - player.global_position.x,
				collider.global_position.z - player.global_position.z
			).length()

			if dist_to_player <= radius:
				# Find all mesh instances in this collider
				var meshes = _find_mesh_instances(collider)
				for mesh in meshes:
					# Make this mesh transparent
					_make_transparent(mesh)
					currently_occluding.append(mesh)

		# Continue ray from hit point
		ray_origin = result.position + (ray_target - ray_origin).normalized() * 0.01
		query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
		query.exclude = [player]
		result = space_state.intersect_ray(query)

func _find_mesh_instances(node: Node) -> Array:
	var meshes = []

	if node is MeshInstance3D:
		meshes.append(node)

	for child in node.get_children():
		meshes.append_array(_find_mesh_instances(child))

	return meshes

func _make_transparent(mesh: MeshInstance3D):
	# Store original material if not already stored
	if not original_materials.has(mesh):
		original_materials[mesh] = mesh.material_override

	# Check if we already created a transparent version
	if not transparent_materials.has(mesh):
		transparent_materials[mesh] = _create_transparent_material(mesh)

	# Apply transparent material
	mesh.material_override = transparent_materials[mesh]

func _create_transparent_material(mesh: MeshInstance3D) -> Material:
	var original = mesh.material_override
	var trans_material = StandardMaterial3D.new()

	# Copy properties from original material if possible
	if original is StandardMaterial3D:
		# Copy textures
		if original.albedo_texture:
			trans_material.albedo_texture = original.albedo_texture

		# Get original color but make transparent
		var color = original.albedo_color
		trans_material.albedo_color = Color(color.r, color.g, color.b, transparency)
	else:
		# Default semi-transparent material
		trans_material.albedo_color = Color(0.7, 0.7, 0.7, transparency)

	# Setup transparency
	trans_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Add outline if enabled
	if outline_enabled:
		trans_material.edge_width = 1.0 # Enable edge
		trans_material.edge_color = outline_color

	return trans_material

# Hexagon math (if needed for more complex shape testing)
func _point_in_hexagon(point: Vector2, center: Vector2, size: float) -> bool:
	# Convert point to local coordinates
	var local = point - center

	# For a regular hexagon
	var q = abs(local.x) * 0.866025 + abs(local.y) * 0.5
	var r = abs(local.y)

	return max(q, r) <= size
