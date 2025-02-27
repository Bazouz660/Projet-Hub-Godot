extends Node
class_name TerrainChunkNoise

static func _generate_noise_data(chunk: TerrainChunk) -> void:
	# Precompute noise values for an extended grid (+ border)
	var vertex_count = chunk.vertex_count
	var grid_position = chunk.grid_position
	var config = TerrainChunk.config
	var extended_vertex_count = vertex_count + 6

	chunk.continentalness_data = PackedFloat32Array()
	chunk.erosion_data = PackedFloat32Array()
	chunk.peaks_and_valleys_data = PackedFloat32Array()
	chunk.humidity_data = PackedFloat32Array()
	chunk.temperature_data = PackedFloat32Array()
	chunk.difficulty_data = PackedFloat32Array()

	chunk.continentalness_data.resize(extended_vertex_count * extended_vertex_count)
	chunk.erosion_data.resize(extended_vertex_count * extended_vertex_count)
	chunk.peaks_and_valleys_data.resize(extended_vertex_count * extended_vertex_count)
	chunk.humidity_data.resize(extended_vertex_count * extended_vertex_count)
	chunk.temperature_data.resize(extended_vertex_count * extended_vertex_count)
	chunk.difficulty_data.resize(extended_vertex_count * extended_vertex_count)

	for z in range(-3, vertex_count + 3):
		for x in range(-3, vertex_count + 3):
			var world_x = (float(x) / config.vertex_per_meter) + (grid_position.x * config.chunk_size)
			var world_z = (float(z) / config.vertex_per_meter) + (grid_position.y * config.chunk_size)
			var index = (z + 3) * extended_vertex_count + (x + 3)

			# Sample all noise values
			var continentalness = config.continentalness.get_noise_2d(world_x, world_z)
			var erosion = config.erosion.get_noise_2d(world_x, world_z)
			var peaks_valleys = config.peaks_and_valeys.get_noise_2d(world_x, world_z)
			var humidity = config.humidity.get_noise_2d(world_x, world_z)
			var temperature = config.temperature.get_noise_2d(world_x, world_z)
			var difficulty = config.difficulty.get_noise_2d(world_x, world_z)

			chunk.continentalness_data[index] = continentalness
			chunk.erosion_data[index] = erosion
			chunk.peaks_and_valleys_data[index] = peaks_valleys
			chunk.humidity_data[index] = humidity
			chunk.temperature_data[index] = temperature
			chunk.difficulty_data[index] = difficulty

			# Only fill height and biome data for the inner grid
			if x >= 0 and x < vertex_count and z >= 0 and z < vertex_count:
				var height = _sample_height(chunk, world_x, world_z)
				chunk.height_data[z * vertex_count + x] = height
				var biome = TerrainChunkBiome._determine_biome(chunk, world_x, world_z)
				chunk.biome_data[z * vertex_count + x] = biome.id

static func _sample_height(chunk: TerrainChunk, world_x: float, world_z: float) -> float:
	var config = TerrainChunk.config
	var index = chunk.get_index_from_world_coords(world_x, world_z)
	var continentalness: float
	var erosion: float
	var peaks_and_valleys: float
	if index >= chunk.continentalness_data.size():
		push_warning("Index out of bounds: index is " + str(index) + " and data size is " + str(chunk.continentalness_data.size()))
		continentalness = config.continentalness.get_noise_2d(world_x, world_z)
		erosion = config.erosion.get_noise_2d(world_x, world_z)
		peaks_and_valleys = config.peaks_and_valeys.get_noise_2d(world_x, world_z)
	else:
		continentalness = chunk.continentalness_data[index]
		erosion = chunk.erosion_data[index]
		peaks_and_valleys = chunk.peaks_and_valleys_data[index]

	var continentalness_height = config.continentalness_curve.sample_baked(continentalness)
	var peaks_height = config.peaks_and_valeys_curve.sample_baked(peaks_and_valleys)
	var erosion_height = config.erosion_curve.sample_baked(erosion)
	return continentalness_height + erosion_height + peaks_height

static func sample_height(world_x: float, world_z: float) -> float:
	var config = TerrainChunk.config
	var continentalness = config.continentalness.get_noise_2d(world_x, world_z)
	var erosion = config.erosion.get_noise_2d(world_x, world_z)
	var peaks_and_valleys = config.peaks_and_valeys.get_noise_2d(world_x, world_z)
	var continentalness_height = config.continentalness_curve.sample_baked(continentalness)
	var peaks_height = config.peaks_and_valeys_curve.sample_baked(peaks_and_valleys)
	var erosion_height = config.erosion_curve.sample_baked(erosion)
	return continentalness_height + erosion_height + peaks_height

static func sample_normal(world_x: float, world_z: float) -> Vector3:
	var dx := 0.01
	var dz := 0.01
	var x0 := sample_height(world_x - dx, world_z)
	var x1 := sample_height(world_x + dx, world_z)
	var z0 := sample_height(world_x, world_z - dz)
	var z1 := sample_height(world_x, world_z + dz)
	var normal := Vector3(x0 - x1, 2.0, z0 - z1)
	return normal.normalized()
