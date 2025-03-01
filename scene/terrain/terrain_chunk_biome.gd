extends Node
class_name TerrainChunkBiome

static func _get_best_biome(height: float, humidity: float, temperature: float, difficulty: float) -> Biome:
	var best_biome: Biome = null
	var best_distance: float = 10000.0 # Large initial value
	var EPSILON = 0.0001

	for b in TerrainChunk.biomes:
		# Enforce height constraint: skip if height is outside range
		if height < b.height_range.x || height > b.height_range.y:
			continue

		# Compute centers
		var height_center = (b.height_range.x + b.height_range.y) / 2.0
		var humidity_center = (b.humidity_range.x + b.humidity_range.y) / 2.0
		var temperature_center = (b.temperature_range.x + b.temperature_range.y) / 2.0
		var difficulty_center = (b.difficulty_range.x + b.difficulty_range.y) / 2.0

		# Compute safe half-ranges
		var safe_height_range = max((b.height_range.y - b.height_range.x) / 2.0, EPSILON)
		var safe_humidity_range = max((b.humidity_range.y - b.humidity_range.x) / 2.0, EPSILON)
		var safe_temperature_range = max((b.temperature_range.y - b.temperature_range.x) / 2.0, EPSILON)
		var safe_difficulty_range = max((b.difficulty_range.y - b.difficulty_range.x) / 2.0, EPSILON)

		# Compute normalized differences
		var height_diff = (height - height_center) / safe_height_range
		var humidity_diff = (humidity - humidity_center) / safe_humidity_range
		var temperature_diff = (temperature - temperature_center) / safe_temperature_range
		var difficulty_diff = (difficulty - difficulty_center) / safe_difficulty_range

		# Weighted squared distance
		var distance = (4.0 * height_diff * height_diff +
						humidity_diff * humidity_diff +
						temperature_diff * temperature_diff +
						0.5 * difficulty_diff * difficulty_diff)

		if distance < best_distance:
			best_distance = distance
			best_biome = b

	# Fallback in case no biome qualifies (should be rare with proper ranges)
	if best_biome == null:
		best_biome = TerrainChunk.biomes[0] # Default to first biome (e.g., ocean)

	return best_biome

static func _determine_biome(chunk: TerrainChunk, world_x: float, world_z: float) -> Biome:
	var height = chunk.get_height_at_world_position(Vector3(world_x, 0.0, world_z))
	var index = chunk.get_index_from_world_coords(world_x, world_z)
	var humidity = chunk.humidity_data[index]
	var temperature = chunk.temperature_data[index]
	var difficulty = chunk.difficulty_data[index]
	return _get_best_biome(height, humidity, temperature, difficulty)

static func _determine_biome_precise(chunk: TerrainChunk, world_x: float, world_z: float) -> Biome:
	var config = TerrainChunk.config
	var height = chunk.get_interpolated_height_at_world_position(Vector3(world_x, 0.0, world_z))
	var humidity = config.humidity.get_noise_2d(world_x, world_z)
	var temperature = config.temperature.get_noise_2d(world_x, world_z)
	var difficulty = config.difficulty.get_noise_2d(world_x, world_z)
	return _get_best_biome(height, humidity, temperature, difficulty)

static func determine_biome(world_x: float, world_z: float) -> Biome:
	var config = TerrainChunk.config
	var continentalness = config.continentalness.get_noise_2d(world_x, world_z)
	var erosion = config.erosion.get_noise_2d(world_x, world_z)
	var peaks_and_valleys = config.peaks_and_valeys.get_noise_2d(world_x, world_z)
	var height = config.continentalness_curve.sample_baked(continentalness) + \
				 config.erosion_curve.sample_baked(erosion) + \
				 config.peaks_and_valeys_curve.sample_baked(peaks_and_valleys)

	var humidity = config.humidity.get_noise_2d(world_x, world_z)
	var temperature = config.temperature.get_noise_2d(world_x, world_z)
	var difficulty = config.difficulty.get_noise_2d(world_x, world_z)
	return _get_best_biome(height, humidity, temperature, difficulty)
