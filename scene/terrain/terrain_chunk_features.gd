extends Node
class_name TerrainChunkFeatures

static func _generate_features_positions(chunk: TerrainChunk) -> Dictionary[Vector3i, Array]:
	var positions: Dictionary[Vector3i, Array] = {}

	# Create a list to track all placed features with their positions and radii
	var placed_features: Array[Dictionary] = []

	for biome_index in range(TerrainChunk.biomes.size()):
		var biome = TerrainChunk.biomes[biome_index]
		var feature_layer_index = 0

		for feature_layer in biome.feature_layers:
			var feature_index = 0
			for feature_params in feature_layer.features:
				feature_params = feature_params as FeatureGenParams
				var density = feature_params.density
				var target_features = int((density / 300.0) * chunk.grid_size)
				var max_attempts = target_features * 3
				var candidate_positions = []
				candidate_positions.resize(target_features)
				var valid_count = 0

				# Get feature min_radius - only check for instance type features
				var min_radius = 0.0
				if feature_params.feature.type == Feature.FeatureType.INSTANCE:
					min_radius = feature_params.feature.min_radius

				# Get noise parameters
				var spawn_noise = feature_params.spawn_noise
				var use_noise = spawn_noise != null
				var noise_threshold = feature_params.spawn_noise_threshold

				# Get patch mask parameters
				var patch_mask = feature_params.patch_mask_noise
				var use_patch_mask = patch_mask != null
				var patch_threshold = feature_params.patch_mask_threshold

				for _i in range(max_attempts):
					if valid_count >= target_features:
						break

					var cell_x = chunk.rng.randi() % chunk.cells_per_side
					var cell_z = chunk.rng.randi() % chunk.cells_per_side
					var grid_index = cell_z * chunk.cells_per_side + cell_x

					if chunk.occupied_grid[grid_index] == 1:
						continue

					var vertex_x = int(cell_x * chunk.vertex_factor)
					var vertex_z = int(cell_z * chunk.vertex_factor)
					if vertex_x >= chunk.safe_vertex_count or vertex_z >= chunk.safe_vertex_count:
						continue

					var world_x = chunk.world_offset_x + (cell_x * TerrainChunk.CELL_SIZE) + chunk.rng.randf() * TerrainChunk.CELL_SIZE
					var world_z = chunk.world_offset_z + (cell_z * TerrainChunk.CELL_SIZE) + chunk.rng.randf() * TerrainChunk.CELL_SIZE

					# Check patch mask first - this determines if features can appear in this region at all
					if use_patch_mask:
						var mask_value = patch_mask.get_noise_2d(world_x, world_z)
						mask_value = (mask_value + 1.0) / 2.0 # Normalize to [0,1]
						if mask_value < patch_threshold:
							continue # Skip this position - outside valid patch regions

					# Then check detailed spawn noise for the precise feature placement
					if use_noise:
						var noise_value = spawn_noise.get_noise_2d(world_x, world_z)
						noise_value = (noise_value + 1.0) / 2.0
						if noise_value < noise_threshold:
							continue

					# Rest of your existing code - biome checks, etc.
					var vertex_index = vertex_z * chunk.vertex_count + vertex_x

					var corners = PackedInt32Array([
						chunk.biome_data[vertex_index],
						chunk.biome_data[vertex_index + 1],
						chunk.biome_data[(vertex_z + 1) * chunk.vertex_count + vertex_x],
						chunk.biome_data[(vertex_z + 1) * chunk.vertex_count + vertex_x + 1]
					])
					var valid_corners = corners.count(biome_index)

					# Fast path: all corners match
					if valid_corners == 4:
						var height = chunk.get_interpolated_height_at_world_position(Vector3(world_x, 0.0, world_z))
						var new_position = Vector3(world_x, height, world_z)

						# Skip this position if it's too close to an existing feature
						if min_radius > 0:
							var too_close = false
							for existing in placed_features:
								var distance = new_position.distance_to(existing.position)
								if distance < (min_radius + existing.radius):
									too_close = true
									break

							if too_close:
								continue

						candidate_positions[valid_count] = new_position
						chunk.occupied_grid[grid_index] = 1

						# Add this feature to the placed features list if it has a minimum radius
						if min_radius > 0:
							placed_features.append({
								"position": new_position,
								"radius": min_radius,
								"biome": biome_index,
								"layer": feature_layer_index,
								"feature": feature_index
							})

						valid_count += 1
						continue

					# Edge case: some corners match; verify exact biome
					if valid_corners >= 2:
						var exact_biome = TerrainChunkBiome._determine_biome_precise(chunk, world_x, world_z).id
						if exact_biome != biome_index:
							continue

						var height = chunk.get_interpolated_height_at_world_position(Vector3(world_x, 0.0, world_z))
						var new_position = Vector3(world_x, height, world_z)

						# Skip this position if it's too close to an existing feature
						if min_radius > 0:
							var too_close = false
							for existing in placed_features:
								var distance = new_position.distance_to(existing.position)
								if distance < (min_radius + existing.radius):
									too_close = true
									break

							if too_close:
								continue

						candidate_positions[valid_count] = new_position
						chunk.occupied_grid[grid_index] = 1

						# Add this feature to the placed features list if it has a minimum radius
						if min_radius > 0:
							placed_features.append({
								"position": new_position,
								"radius": min_radius,
								"biome": biome_index,
								"layer": feature_layer_index,
								"feature": feature_index
							})

						valid_count += 1

				if valid_count > 0:
					positions[Vector3i(biome_index, feature_layer_index, feature_index)] = candidate_positions.slice(0, valid_count)
				feature_index += 1
			feature_layer_index += 1
	return positions

static func _instantiate_features(chunk: TerrainChunk, feature_positions: Dictionary[Vector3i, Array]) -> void:
	for key in feature_positions.keys():
		var positions = feature_positions[key]
		var biome: Biome = TerrainChunk.biomes_index_label[key.x]
		#var feature = biome.features[key.y].feature as Feature
		var feature := biome.feature_layers[key.y].features[key.z].feature as Feature
		if not feature:
			continue
		if feature.type == Feature.FeatureType.INSTANCE:
			_instantiate_instances(chunk, feature, positions)
		elif feature.type == Feature.FeatureType.MULTIMESH:
			_instantiate_multimesh(chunk, biome, feature, positions)

static func _instantiate_multimesh(chunk: TerrainChunk, biome: Biome, feature: Feature, positions: Array) -> void:
	var multimesh_instance = MultiMeshInstance3D.new()
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = positions.size()
	multimesh.mesh = feature.mesh
	for i in range(positions.size()):
		multimesh.set_instance_transform(i, Transform3D(Basis(), positions[i]))
	multimesh_instance.multimesh = multimesh
	multimesh_instance.cast_shadow = feature.cast_shadow

	if feature.receive_biome_color:
		var material = multimesh.mesh.surface_get_material(0)
		if material is ShaderMaterial:
			var material_duplicated = material.duplicate() as ShaderMaterial
			material_duplicated.set_shader_parameter(feature.shader_parameter_color_name, biome.color)
			multimesh_instance.material_override = material_duplicated

	chunk.add_child(multimesh_instance)
	multimesh_instance.global_transform.origin = Vector3(0.0, 0.0, 0.0)

static func _instantiate_instances(chunk: TerrainChunk, feature: Feature, positions: Array) -> void:
	for pos in positions:
		_instantiate_feature(chunk, feature, pos)

static func _instantiate_feature(chunk: TerrainChunk, feature: Feature, p_position: Vector3) -> void:
	var scene = feature.scenes[chunk.rng.randi() % feature.scenes.size()]
	var instance = scene.instantiate() as Node3D
	chunk.add_child(instance)
	instance.global_position = p_position
	instance.global_rotation = Vector3(0.0, deg_to_rad(chunk._funny_randf(feature.random_rotation.x, feature.random_rotation.y)), 0.0)
	var random_scale = chunk._funny_randf(feature.random_scale.x, feature.random_scale.y)
	instance.scale = Vector3(random_scale, random_scale, random_scale)

	if feature.follow_normals:
		var normal = TerrainChunk.calculate_terrain_normal(chunk, p_position)
		# Create a quaternion that rotates from the default up to the surface normal.
		# Both vectors must be normalized
		var align_quat = Quaternion(Vector3.UP, normal)
		instance.global_rotation = align_quat.get_euler()
