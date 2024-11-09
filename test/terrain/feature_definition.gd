#feature_definiton.gd
@tool
extends Resource
class_name FeatureDefinition

# Feature Type Enum
enum Type {
	MULTIMESH,  # For grass, small rocks, flowers, etc.
	INSTANCE,   # For larger objects like trees that need individual physics
}

@export var name: String
@export var type: Type

@export_group("Object")
@export var mesh: Mesh
@export var packed_scenes : Array[PackedScene]

@export_group("Geometry")
@export var cast_shadow: bool = true

@export_group("Spawn ranges")
@export var biome_ranges: Array[Vector2]  # Array of min/max biome noise values where this can spawn
@export var elevation_range: Vector2  # min/max height where this can spawn

@export_group("Spawn parameters")
@export var density: int = 1
@export var follow_normal : bool = false
@export var scale_range: Vector2 = Vector2(1.0, 1.0)
@export var spacing: float = 0.3 # Minimum distance between instances

@export_group("Spawn noise")
@export var noise : FastNoiseLite
@export var noise_threshold : float

@export_group("Custom data")
@export var custom_data: Dictionary  # For any additional feature-specific data
