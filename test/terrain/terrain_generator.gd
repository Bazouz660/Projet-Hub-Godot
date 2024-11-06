#terrain_generator.gd
extends RefCounted
class_name TerrainGenerator


class WorkResult:
	var chunk_pos: Vector2
	var mesh_data: Array  # [vertices, indices, uvs]
	var feature_data: Array[Dictionary]  # Array of feature placement data
	
	func _init(pos: Vector2, mesh: Array, features: Array[Dictionary]):
		chunk_pos = pos
		mesh_data = mesh
		feature_data = features


var config: TerrainConfig

func _init(p_config: TerrainConfig):
	config = p_config

func _generate_terrain_data(chunk_pos: Vector2) -> WorkResult:
	# Generate mesh data
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var uvs = PackedVector2Array()
	
	# Create vertices and UV coordinates
	for x in range(config.chunk_size + 1):
		for z in range(config.chunk_size + 1):
			var world_x = (chunk_pos.x * config.chunk_size) + x
			var world_z = (chunk_pos.y * config.chunk_size) + z
			
			var height_sample = config.height_noise.noise.get_noise_2d(world_x, world_z)
			var height = (height_sample * config.height_scale) + config.height_offset
			
			var biome_sample = config.biome_noise.noise.get_noise_2d(world_x, world_z)
			
			vertices.append(Vector3(x * config.grid_size, height, z * config.grid_size))
			uvs.append(Vector2(biome_sample, height_sample))
	
	# Create indices for triangles
	for x in range(config.chunk_size):
		for z in range(config.chunk_size):
			var i = x * (config.chunk_size + 1) + z
			var i_right = i + 1
			var i_down = i + (config.chunk_size + 1)
			var i_down_right = i_down + 1
			
			indices.append_array([i, i_down, i_right])
			indices.append_array([i_right, i_down, i_down_right])
	
	# Generate feature placement data
	var feature_data: Array[Dictionary] = []
	
	for feature_name in FeatureManager.get_definitions():
		var definition = FeatureManager.get_definitions()[feature_name]
		var positions = FeatureManager._generate_feature_positions_threaded(
			chunk_pos,
			definition
		)
		
		if not positions.is_empty():
			feature_data.append({
				"name": feature_name,
				"positions": positions
			})
	
	return WorkResult.new(chunk_pos, [vertices, indices, uvs], feature_data)
