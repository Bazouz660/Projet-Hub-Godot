extends RefCounted
class_name FeatureManager

var feature_definitions: Dictionary = {}
var _config : TerrainConfig

# Cache for commonly accessed values
var _chunk_world_size: float
var _grid_size: float
var _biome_noise: FastNoiseLite
var _height_noise: FastNoiseLite
var _height_scale: float
var _height_offset: float

# Static instance with proper initialization
static var _instance: FeatureManager = null

static func get_instance() -> FeatureManager:
	if _instance == null:
		_instance = FeatureManager.new()
	return _instance

static func set_config(p_config : TerrainConfig):
	print("Features in set_config: ", p_config.features)
	get_instance()._config = p_config
	get_instance()._init_cache()

func _init_cache():
	if not _config:
		return
	_chunk_world_size = _config.chunk_size * _config.grid_size
	_grid_size = _config.grid_size
	_biome_noise = _config.biome_noise.noise
	_height_noise = _config.height_noise.noise
	_height_scale = _config.height_scale
	_height_offset = _config.height_offset


static func register_feature(definition: FeatureDefinition):
	get_instance().feature_definitions.get_or_add(definition.name, definition)
	
static func get_definitions() -> Dictionary:
	return get_instance().feature_definitions


static func apply_features(chunk: TerrainChunk, feature_data: Array):
	for feature in feature_data:
		var definition = get_instance().feature_definitions[feature.name]
		if definition.type == FeatureDefinition.Type.MULTIMESH:
			_create_multimesh_feature(chunk, definition, feature.positions)
		else:  # INSTANCE type
			_create_instanced_feature(chunk, definition, feature.positions)


static func _generate_feature_positions_threaded(
	chunk_pos: Vector2,
	definition: FeatureDefinition
) -> Array:
	var positions: Array = []
	positions.resize(definition.density)  # Pre-allocate array
	var position_count = 0
	var occupied_positions = PackedVector2Array()  # Use PackedVector2Array for better performance
	occupied_positions.resize(definition.density)
	var occupied_count = 0
	
	# Create a new RNG instance for this chunk
	var chunk_rng = RandomNumberGenerator.new()
	# Create a deterministic seed based on chunk position and feature name
	var chunk_seed = get_instance()._config.seed
	chunk_seed = hash(str(chunk_seed) + str(chunk_pos.x) + str(chunk_pos.y) + definition.name)
	chunk_rng.seed = chunk_seed
	
	# Cache frequently accessed values
	var chunk_world_x = chunk_pos.x * get_instance()._chunk_world_size
	var chunk_world_z = chunk_pos.y * get_instance()._chunk_world_size
	var grid_size = get_instance()._grid_size
	var biome_noise = get_instance()._biome_noise
	var height_noise = get_instance()._height_noise
	var height_scale = get_instance()._height_scale
	var height_offset = get_instance()._height_offset
	
	# Pre-calculate range checks
	var min_elevation = definition.elevation_range.x
	var max_elevation = definition.elevation_range.y
	var spacing_squared = definition.spacing * definition.spacing  # Square the spacing once
	
	var max_attempts = definition.density * 2
	for _i in range(max_attempts):
		if position_count >= definition.density:
			break
			
		var local_x = chunk_rng.randf() * get_instance()._chunk_world_size
		var local_z = chunk_rng.randf() * get_instance()._chunk_world_size
		var world_x = chunk_world_x + local_x
		var world_z = chunk_world_z + local_z
		
		# Biome check - exit early if invalid
		var biome_value = biome_noise.get_noise_2d(world_x / grid_size, world_z / grid_size)
		var valid_biome = false
		for biome_range in definition.biome_ranges:
			if biome_value >= biome_range.x and biome_value < biome_range.y:
				valid_biome = true
				break
		
		if not valid_biome:
			continue
		
		# Height check - exit early if invalid
		var height = (height_noise.get_noise_2d(world_x / grid_size, world_z / grid_size) 
			* height_scale) + height_offset
			
		if height < min_elevation or height > max_elevation:
			continue
			
		# Noise threshold check - exit early if invalid
		if is_instance_valid(definition.noise):
			var noise_value = definition.noise.get_noise_2d(world_x / grid_size, world_z / grid_size)
			if noise_value < definition.noise_threshold:
				continue
		
		# Spacing check using squared distance
		var too_close = false
		var new_pos = Vector2(local_x, local_z)
		for i in range(occupied_count):
			var dist_squared = new_pos.distance_squared_to(occupied_positions[i])
			if dist_squared < spacing_squared:
				too_close = true
				break
		
		if too_close:
			continue
		
		# Calculate normal if needed
		var normal = Vector3.UP
		if definition.follow_normal:
			normal = _calculate_terrain_normal(world_x / grid_size, world_z / grid_size)
		
		# Store position and normal
		positions[position_count] = {
			"position": Vector3(local_x, height, local_z),
			"normal": normal
		}
		occupied_positions[occupied_count] = new_pos
		position_count += 1
		occupied_count += 1
	
	# Trim arrays to actual size
	positions.resize(position_count)
	return positions

static func _calculate_terrain_normal(world_x: float, world_z: float) -> Vector3:
	# Sample heights at nearby points to calculate normal
	var sample_distance = get_instance()._grid_size * 0.5
	var h_scale = get_instance()._height_scale
	var h_offset = get_instance()._height_offset
	var noise = get_instance()._height_noise
	
	# Get raw noise values (-1 to 1) and apply scale/offset
	var h_center = (noise.get_noise_2d(world_x, world_z) * h_scale) + h_offset
	var h_right = (noise.get_noise_2d(world_x + sample_distance, world_z) * h_scale) + h_offset
	var h_forward = (noise.get_noise_2d(world_x, world_z + sample_distance) * h_scale) + h_offset
	
	# Create vectors for two edges of the triangle
	var right = Vector3(sample_distance, h_right - h_center, 0.0)
	var forward = Vector3(0.0, h_forward - h_center, sample_distance)
	
	# Cross product to get normal (cross order matters for correct orientation)
	return right.cross(forward).normalized()

static func _create_multimesh_feature(chunk: TerrainChunk, definition: FeatureDefinition, positions: Array):
	var feature_rng = RandomNumberGenerator.new()
	var feature_seed = get_instance()._config.seed
	feature_seed = hash(str(feature_seed) + str(positions) \
	+ str(chunk.global_position.x) + str(chunk.global_position.y) + definition.name)
	feature_rng.seed = feature_seed
	
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = definition.mesh
	
	var position_count = positions.size()
	multi_mesh.instance_count = position_count
	
	# Pre-calculate transformation matrices
	var transforms = []
	transforms.resize(position_count)
	
	for i in range(position_count):
		var pos_data = positions[i]
		var _transform = Transform3D()
		var _scale = feature_rng.randf_range(definition.scale_range.x, definition.scale_range.y)
		
		if definition.follow_normal:
			var normal = pos_data.normal
			# Calculate a proper basis where Y aligns with normal
			var up = normal
			var right = Vector3.RIGHT
			if abs(up.dot(Vector3.UP)) < 0.99:
				right = Vector3.UP.cross(up).normalized()
			else:
				right = Vector3.FORWARD.cross(up).normalized()
			var forward = up.cross(right)
			var basis = Basis(right, up, forward)
			
			# Apply random rotation around normal
			var angle = feature_rng.randf() * TAU
			basis = basis.rotated(normal, angle)
			
			_transform.basis = basis
		else:
			_transform = _transform.rotated(Vector3.UP, feature_rng.randf() * TAU)
		
		_transform = _transform.scaled(Vector3(_scale, _scale, _scale))
		_transform.origin = pos_data.position
		transforms[i] = _transform
	
	# Batch set transforms
	for i in range(position_count):
		multi_mesh.set_instance_transform(i, transforms[i])
	
	var multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.multimesh = multi_mesh
	multi_mesh_instance.cast_shadow = definition.cast_shadow
	
	chunk.feature_container.multimesh_features[definition.name] = multi_mesh_instance
	chunk.feature_container.add_child(multi_mesh_instance)

static func _create_instanced_feature(chunk: TerrainChunk, definition: FeatureDefinition, positions: Array):
	# Create a deterministic RNG for this specific feature in this chunk
	var feature_rng = RandomNumberGenerator.new()
	var feature_seed = get_instance()._config.seed
	feature_seed = hash(str(feature_seed) + str(positions) \
	+ str(chunk.global_position.x) + str(chunk.global_position.y) + definition.name)
	feature_rng.seed = feature_seed
	
	var instances: Array[Node3D] = []
	instances.resize(positions.size())
	var scenes = definition.packed_scenes
	var scenes_count = scenes.size()
	
	# Pre-calculate random values
	var random_indices = []
	var random_scales = []
	random_indices.resize(positions.size())
	random_scales.resize(positions.size())
	
	for i in range(positions.size()):
		random_indices[i] = feature_rng.randi_range(0, scenes_count - 1)
		random_scales[i] = feature_rng.randf_range(definition.scale_range.x, definition.scale_range.y)
	
	# Batch instantiate and transform
	for i in range(positions.size()):
		var instance = scenes[random_indices[i]].instantiate()
		var pos_data = positions[i]
		
		if definition.follow_normal:
			var normal = pos_data.normal
			# Calculate a proper basis where Y aligns with normal
			var up = normal
			var right = Vector3.RIGHT
			if abs(up.dot(Vector3.UP)) < 0.99:
				right = Vector3.UP.cross(up).normalized()
			else:
				right = Vector3.FORWARD.cross(up).normalized()
			var forward = up.cross(right)
			var basis = Basis(right, up, forward)
			
			# Apply random rotation around normal
			var angle = feature_rng.randf() * TAU
			basis = basis.rotated(normal, angle)
			
			instance.transform.basis = basis
		else:
			instance.rotation.y = feature_rng.randf() * TAU
			
		instance.scale = Vector3(random_scales[i], random_scales[i], random_scales[i])
		instance.position = pos_data.position
		
		chunk.feature_container.add_child(instance)
		instances[i] = instance
	
	chunk.feature_container.instanced_features[definition.name] = instances
