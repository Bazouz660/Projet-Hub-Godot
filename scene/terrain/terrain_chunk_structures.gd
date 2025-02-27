extends Node
class_name TerrainChunkStructures

# Apply structure deformations to a given chunk by querying the global structure manager.
static func _apply_deformations(chunk: TerrainChunk) -> void:
	# Create an AABB for the chunk (extend vertically to cover all terrain)
	var chunk_area = AABB(
		Vector3(chunk.world_offset_x, -1000, chunk.world_offset_z),
		Vector3(TerrainChunk.config.chunk_size, 2000, TerrainChunk.config.chunk_size)
	)

	chunk_area = chunk_area.grow(chunk.size * 0.5)

	# Get all global structures overlapping this chunk
	var structures = StructureManager.get_structures_in_area(chunk_area)

	# Process each structure
	for structure_data in structures:
		_apply_structure_deformation(chunk, structure_data)
		_fill_positions(chunk, structure_data)

static func _fill_positions(chunk: TerrainChunk, structure_data: StructureData) -> void:
	var structure_pos = structure_data.position
	var structure_size = structure_data.size

	# Convert structure bounds from world space to chunk-local cell indices.
	var local_min_x = (structure_pos.x - chunk.world_offset_x) / TerrainChunk.CELL_SIZE
	var local_min_z = (structure_pos.z - chunk.world_offset_z) / TerrainChunk.CELL_SIZE
	var local_max_x = (structure_pos.x + structure_size.x - chunk.world_offset_x) / TerrainChunk.CELL_SIZE
	var local_max_z = (structure_pos.z + structure_size.z - chunk.world_offset_z) / TerrainChunk.CELL_SIZE

	# Use floor/ceil to cover the full range of cells the structure covers.
	var cell_min_x = int(floor(local_min_x))
	var cell_min_z = int(floor(local_min_z))
	var cell_max_x = int(ceil(local_max_x))
	var cell_max_z = int(ceil(local_max_z))

	# Add a margin of 10 cells around the structure.
	cell_min_x = max(0, cell_min_x - 10)
	cell_min_z = max(0, cell_min_z - 10)
	cell_max_x = min(chunk.cells_per_side, cell_max_x + 10)
	cell_max_z = min(chunk.cells_per_side, cell_max_z + 10)

	for cell_x in range(cell_min_x, cell_max_x):
		for cell_z in range(cell_min_z, cell_max_z):
			# Calculate the 1D index for the occupied_grid.
			var index = cell_z * chunk.cells_per_side + cell_x
			# Only mark if the cell index is valid.
			if cell_x >= 0 and cell_x < chunk.cells_per_side and cell_z >= 0 and cell_z < chunk.cells_per_side:
				chunk.occupied_grid[index] = 1


static func _apply_structure_deformation(chunk: TerrainChunk, structure_data: StructureData) -> void:
	var structure_pos = structure_data.position
	var structure_size = structure_data.size

	# Calculate the footprint bounds in world coordinates.
	var min_x = floor(structure_pos.x)
	var max_x = ceil(structure_pos.x + structure_size.x)
	var min_z = floor(structure_pos.z)
	var max_z = ceil(structure_pos.z + structure_size.z)

	# Define a blend distance (in world units) outside the footprint.
	var blend_distance = 8.0

	# Loop over an area that covers both the footprint and a surrounding blending margin.
	var start_x = int(floor(min_x - blend_distance))
	var end_x = int(ceil(max_x + blend_distance))
	var start_z = int(floor(min_z - blend_distance))
	var end_z = int(ceil(max_z + blend_distance))

	for x in range(start_x, end_x):
		for z in range(start_z, end_z):
			var world_pos = Vector3(x, 0, z)
			var current_height = chunk.get_height_at_world_position(world_pos)
			var new_height = current_height

			# Inside the structure's footprint: apply full deformation (flat terrain).
			if (x >= min_x and x < max_x) and (z >= min_z and z < max_z):
				new_height = structure_data.position.y
			else:
				# Outside the footprint: compute the distance to the nearest edge.
				var dx = 0.0
				if x < min_x:
					dx = min_x - x
				elif x >= max_x:
					dx = x - max_x

				var dz = 0.0
				if z < min_z:
					dz = min_z - z
				elif z >= max_z:
					dz = z - max_z

				var distance = sqrt(dx * dx + dz * dz)

				# If within the blend region, compute a blend factor.
				if distance < blend_distance:
					# At the footprint boundary (distance = 0) blend fully to structure height.
					# At the outer edge (distance = blend_distance) retain original height.
					var blend_factor = 1.0 - smoothstep(0, blend_distance, distance)
					new_height = lerp(current_height, structure_data.position.y, blend_factor)
				# Else, leave the terrain height unchanged.

			chunk.set_height_at_world_position(world_pos, new_height)
			chunk.set_biome_at_world_position(world_pos, TerrainChunkBiome._determine_biome_precise(chunk, x, z).id)
