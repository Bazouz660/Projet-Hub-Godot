extends Node
class_name TerrainChunkMesh

static func _generate_water_mesh(chunk) -> PlaneMesh:
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(TerrainChunk.config.chunk_size, TerrainChunk.config.chunk_size)
	mesh.subdivide_depth = chunk.vertex_count - 1
	mesh.subdivide_width = chunk.vertex_count - 1
	return mesh

static func _generate_mesh(chunk) -> ArrayMesh:
	var config = TerrainChunk.config
	var vertex_spacing = 1.0 / config.vertex_per_meter
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGB_FLOAT)
	st.set_custom_format(1, SurfaceTool.CUSTOM_RGB_FLOAT)
	var extended_vertex_count = chunk.vertex_count + 6

	for z in range(-3, chunk.vertex_count + 3):
		for x in range(-3, chunk.vertex_count + 3):
			var index = (z + 3) * extended_vertex_count + (x + 3)
			var humidity = chunk.humidity_data[index]
			var temperature = chunk.temperature_data[index]
			var difficulty = chunk.difficulty_data[index]

			# Only process inner grid vertices
			if x < 0 or x >= chunk.vertex_count or z < 0 or z >= chunk.vertex_count:
				continue

			var height = chunk.height_data[z * chunk.vertex_count + x]
			var vertex = Vector3(x * vertex_spacing, height * config.height_scale, z * vertex_spacing)
			var uv = Vector2(float(x) / (chunk.vertex_count - 1), float(z) / (chunk.vertex_count - 1))
			st.set_uv(uv)

			var biome_index = chunk.biome_data[z * chunk.vertex_count + x]
			var color: Color = TerrainChunk.biomes[biome_index].color
			st.set_custom(0, color)

			var normalized_height = (height - TerrainChunk.min_height) / (TerrainChunk.max_height - TerrainChunk.min_height)
			st.set_custom(0, Color(normalized_height, humidity, temperature))
			st.set_custom(1, Color(difficulty, 0.0, 0.0))
			st.set_color(color)
			st.add_vertex(vertex)

	# Generate triangle indices
	for z in range(chunk.vertex_count - 1):
		for x in range(chunk.vertex_count - 1):
			var i = z * chunk.vertex_count + x
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(i + chunk.vertex_count)

			st.add_index(i + 1)
			st.add_index(i + chunk.vertex_count + 1)
			st.add_index(i + chunk.vertex_count)

	st.generate_normals()
	st.generate_tangents()
	return st.commit()

static func _generate_chunk_borders_debug_mesh() -> BoxMesh:
	var config = TerrainChunk.config
	var size = config.chunk_size

	var mesh = BoxMesh.new()
	mesh.size = Vector3(size, 100.0, size)
	return mesh

static func create_heightmap_collision(chunk: TerrainChunk) -> HeightMapShape3D:
	var shape := HeightMapShape3D.new()
	shape.map_depth = chunk.vertex_count
	shape.map_width = chunk.vertex_count
	shape.map_data = chunk.height_data
	return shape
