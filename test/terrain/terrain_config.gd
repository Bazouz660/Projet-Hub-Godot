# terrain_config.gd

extends Resource
class_name TerrainConfig

@export var seed: int = 0

# Chunk settings
@export var chunk_size: int = 16
@export var view_distance: int = 2
@export var player_path: NodePath
@export var grid_size: float = 1.0

# Terrain generation
@export var height_noise: NoiseTexture2D
@export var biome_noise: NoiseTexture2D
@export var height_scale: float = 10.0
@export var height_offset: float = -5.0
@export var water_level: float = 0.0

# Biome settings
@export_group("Biome Settings")
@export var mountain_threshold: float = 0.7
@export var forest_threshold: float = 0.4
@export var beach_threshold: float = 0.2
@export var terrain_material: ShaderMaterial
@export var water_material: ShaderMaterial

# Feature settings
@export_group("Feature Settings")
@export var enable_features: bool = true
@export var features: Array[FeatureDefinition]

# Threading settings
@export_group("Threading Settings")
@export var use_threading: bool = true
@export var max_concurrent_jobs: int = 4

func validate() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not height_noise:
		warnings.append("Height NoiseTexture2D is not set!")
	if not biome_noise:
		warnings.append("Biome NoiseTexture2D is not set!")
	if not terrain_material:
		warnings.append("Terrain Material is not set!")
	if not water_material:
		warnings.append("Water Material is not set!")
	if player_path.is_empty():
		warnings.append("Player path is not set!")
	return warnings
