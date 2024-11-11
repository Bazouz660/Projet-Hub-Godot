#terrain_chunk.gd
extends StaticBody3D
class_name TerrainChunk

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var water_mesh_instance: MeshInstance3D
var config : TerrainConfig
var feature_container : FeatureContainer

func _init(p_config : TerrainConfig):
	config = p_config
	# Create mesh instance
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	mesh_instance.material_override = config.terrain_material

	# Create collision shape
	collision_shape = CollisionShape3D.new()
	add_child(collision_shape)

	# Create water mesh
	water_mesh_instance = MeshInstance3D.new()
	add_child(water_mesh_instance)
	_setup_water_mesh()

	# Create feature container
	feature_container = FeatureContainer.new()
	add_child(feature_container)

func _setup_water_mesh():
	var plane = PlaneMesh.new()
	plane.size = Vector2(config.chunk_size * config.grid_size, config.chunk_size * config.grid_size)
	plane.subdivide_depth = config.chunk_size
	plane.subdivide_width = config.chunk_size
	
	water_mesh_instance.mesh = plane
	water_mesh_instance.material_override = config.water_material
	water_mesh_instance.position = Vector3(
		plane.size.x / 2.0,
		config.water_level,
		plane.size.y / 2.0
	)

func apply_mesh_data(mesh_data: ArrayMesh):
	mesh_instance.mesh = mesh_data
	mesh_instance.material_override = config.terrain_material
	mesh_instance.material_override.set_meta("type", "terrain")
	
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(mesh_data.get_faces())
	collision_shape.shape = shape

func _exit_tree():
	feature_container.clear_features()
	water_mesh_instance.queue_free()
	mesh_instance.queue_free()
	collision_shape.queue_free()
