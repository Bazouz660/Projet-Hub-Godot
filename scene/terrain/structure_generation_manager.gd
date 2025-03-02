extends Node
class_name StructureGenerationManager

# Store structure generation parameters
static var structure_gen_params: Array[StructureGenParams] = []

# Initialize structure generation parameters
static func initialize(params: Array[StructureGenParams]) -> void:
	structure_gen_params = params

# Not used in this example, but could be used to update parameters at runtime
# # Get appropriate structure for a position based on terrain parameters
# static func get_structure_for_position(
# 	position: Vector3,
# 	difficulty: float,
# 	biome_type: String
# ) -> PackedScene:
# 	# Filter structures by difficulty
# 	var valid_structures: Array[StructureGenParams] = []

# 	for params in structure_gen_params:
# 		if difficulty < params.difficulty_min and difficulty > params.difficulty_max:
# 			continue
# 		valid_structures.append(params)

# 	# If no valid structures, return null
# 	if valid_structures.is_empty():
# 		return null

# 	# Choose randomly from valid structures
# 	# You could weight this by density or other factors
# 	var chosen_params = valid_structures[randi() % valid_structures.size()]
# 	return chosen_params.structure

# Generate structure data for a region
static func generate_structure_data_for_region(
	region_min: Vector2,
	region_max: Vector2,
	rng: RandomNumberGenerator
) -> Array[StructureData]:
	var structures: Array[StructureData] = []

	# Grid sampling to avoid clustering
	var grid_size = 32.0 # Size of each grid cell for distribution

	# For each structure type
	for params in structure_gen_params:
		# Calculate grid cells in this region
		var grid_cells_x = int(ceil((region_max.x - region_min.x) / grid_size))
		var grid_cells_z = int(ceil((region_max.y - region_min.y) / grid_size))
		var total_cells = grid_cells_x * grid_cells_z

		# Calculate how many structures to place based on density
		var structures_to_place = int(total_cells * params.density)

		# Randomly select cells to place structures in
		var selected_cells = []
		for i in range(structures_to_place):
			if selected_cells.size() >= total_cells:
				break # Avoid infinite loop if density > 1.0

			var cell_index = rng.randi() % total_cells
			if not selected_cells.has(cell_index):
				selected_cells.append(cell_index)

		# Place structures in selected cells
		for cell_index in selected_cells:
			var cell_x = cell_index % grid_cells_x
			var cell_z = cell_index / grid_cells_x

			# Add randomness within the cell
			var offset_x = rng.randf() * grid_size
			var offset_z = rng.randf() * grid_size

			var x = region_min.x + (cell_x * grid_size) + offset_x
			var z = region_min.y + (cell_z * grid_size) + offset_z

			# Get terrain data at this position
			var height = TerrainChunkNoise.sample_height(x, z)
			var difficulty = Utils.get_normalized_noise_2d(TerrainChunk.config.difficulty, x, z)
			# Determine biome at this position
			var biome = TerrainChunkBiome.determine_biome(x, z)
			var biome_name = biome.label

			# Check if structure type matches difficulty range
			if difficulty < params.difficulty_min or difficulty > params.difficulty_max:
				continue

			if not params.valid_biomes.is_empty() and not params.valid_biomes.has(biome_name):
				continue

			# Create structure data based on structure type
			var data = StructureData.new()
			data.position = Vector3(x, height, z)
			data.size = params.structure_data.size
			data.rotation_degrees = Vector3(0, rng.randf_range(0, 360), 0)
			data.structure_scene = params.structure

			structures.append(data)

	return structures
