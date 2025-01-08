extends Node
class_name MaterialDetector

## The maximum distance to check for materials
@export var detection_distance: float = 1.0

## A list of nodes to exclude from detection
@export var exceptions: Array[CollisionObject3D] = []

# Internal variables
var _ray_cast: RayCast3D
var _current_material: Material = null
var _last_position: Vector3 = Vector3.ZERO

## Emitted when the material under the target changes
signal material_changed(new_material: Material)
## Emitted with detailed information about the detected surface
signal surface_detected(info: Dictionary)

func _ready() -> void:
	# Create internal RayCast3D
	_ray_cast = RayCast3D.new()
	_ray_cast.target_position = Vector3(0, -detection_distance, 0)
	add_child(_ray_cast)

	# Add exlusion mask for the target node
	for exception in exceptions:
		_ray_cast.add_exception(exception)

func check_material() -> Dictionary:
	if not _ray_cast.is_colliding():
		if _current_material != null:
			_current_material = null
			emit_signal("material_changed", null)
		return {}

	var collision_point = _ray_cast.get_collision_point()

	# Skip if we haven't moved enough
	if collision_point.distance_to(_last_position) < 0.01:
		return {}

	_last_position = collision_point

	var collider = _ray_cast.get_collider()
	if not collider:
		return {}

	if collider is CSGBox3D:
		var csg_box = collider as CSGBox3D
		var _surface_info = _get_surface_info(csg_box.material, null, collision_point, collider)
		return _surface_info

	var mesh_instance = find_mesh_instance(collider)
	if not mesh_instance:
		return {}

	var surface_info = _get_surface_info(get_material_from_mesh(mesh_instance), mesh_instance, collision_point, collider)

	return surface_info

func _get_surface_info(material: Material, mesh_instance: MeshInstance3D, collision_point: Vector3, collider: Node) -> Dictionary:
	var type: String
	#print("Material found: ", material.resource_path.get_file())
	if material and material.has_meta("type"):
		type = material.get_meta("type")
		#print("Material type: ", type)
		if type == "terrain":
			type = TerrainSystem.get_biome_material()
	else:
		type = "Unknown"
		#print("Material type: Unknown")

	var surface_info = {
		"material": material,
		"mesh_instance": mesh_instance,
		"collision_point": collision_point,
		"collision_normal": _ray_cast.get_collision_normal(),
		"collider": collider,
		"type": type
	}

	if material != _current_material:
		_current_material = material
		# Emit basic material change signal
		emit_signal("material_changed", material)
		# Emit detailed surface information
		emit_signal("surface_detected", surface_info)

	return surface_info

func find_mesh_instance(node: Node) -> MeshInstance3D:
	# First check if the node itself is a MeshInstance3D
	if node is MeshInstance3D:
		return node

	# Check if it has a direct child that's a MeshInstance3D
	for child in node.get_children():
		if child is MeshInstance3D:
			return child

	# Search parent and siblings
	var parent = node.get_parent()
	if parent:
		for sibling in parent.get_children():
			if sibling is MeshInstance3D:
				return sibling

	return null

func get_material_from_mesh(mesh_instance: MeshInstance3D) -> Material:
	# Try to get material from mesh instance surface
	var material = mesh_instance.get_active_material(0)
	if material:
		return material

	# If no override material, try to get it from the mesh itself
	var mesh = mesh_instance.mesh
	if mesh:
		material = mesh.surface_get_material(0)
		if material:
			return material

	return null

## Returns the current material being detected
func get_current_material() -> Material:
	return _current_material
