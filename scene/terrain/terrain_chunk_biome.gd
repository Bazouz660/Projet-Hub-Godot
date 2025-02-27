extends Node
class_name TerrainChunkBiome

static func _get_best_biome(height: float, humidity: float, temperature: float, difficulty: float) -> Biome:
	var best_biome: Biome = null
	var best_score: float = -10000.0
	var EPSILON = 0.0001

	# First filter: Only consider biomes where the height is in range
	var valid_biomes = []

	for b in TerrainChunk.biomes:
		if height >= b.height_range.x && height <= b.height_range.y:
			valid_biomes.append(b)

	# If no biome's height range includes this height, fall back to the closest one
	if valid_biomes.is_empty():
		var closest_biome = null
		var closest_distance = INF

		for b in TerrainChunk.biomes:
			var dist_to_min = abs(height - b.height_range.x)
			var dist_to_max = abs(height - b.height_range.y)
			var min_dist = min(dist_to_min, dist_to_max)

			if min_dist < closest_distance:
				closest_distance = min_dist
				closest_biome = b

		return closest_biome

	# Among the height-valid biomes, find the best match based on other parameters
	for b in valid_biomes:
		var score = 0.0

		# Height is already in range, so give a base score
		score += 3.0 # Base score for being in height range

		# --- Humidity Scoring (smooth falloff) ---
		var humidity_center = (b.humidity_range.x + b.humidity_range.y) / 2.0
		var humidity_range = (b.humidity_range.y - b.humidity_range.x) / 2.0
		var safe_humidity_range = max(humidity_range, EPSILON)
		var humidity_diff = abs(humidity - humidity_center)

		# Smoother falloff for humidity
		var humidity_factor = 1.0 / (1.0 + pow(humidity_diff / safe_humidity_range, 2.0))
		score += humidity_factor

		# --- Temperature Scoring (smooth falloff) ---
		var temperature_center = (b.temperature_range.x + b.temperature_range.y) / 2.0
		var temperature_range = (b.temperature_range.y - b.temperature_range.x) / 2.0
		var safe_temperature_range = max(temperature_range, EPSILON)
		var temperature_diff = abs(temperature - temperature_center)

		# Smoother falloff for temperature
		var temperature_factor = 1.0 / (1.0 + pow(temperature_diff / safe_temperature_range, 2.0))
		score += temperature_factor

		# --- Difficulty Scoring (smooth falloff) ---
		var difficulty_center = (b.difficulty_range.x + b.difficulty_range.y) / 2.0
		var difficulty_range = (b.difficulty_range.y - b.difficulty_range.x) / 2.0
		var safe_difficulty_range = max(difficulty_range, EPSILON)
		var difficulty_diff = abs(difficulty - difficulty_center)

		# Smoother falloff for difficulty
		var difficulty_factor = 1.0 / (1.0 + pow(difficulty_diff / safe_difficulty_range, 2.0))
		score += difficulty_factor

		if score > best_score:
			best_score = score
			best_biome = b

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
