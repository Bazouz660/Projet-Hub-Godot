extends Resource
class_name Biome

@export var label: String
var id: int
@export var color: Color
@export var height_range: Vector2 = Vector2(-30, 80)
@export var humidity_range: Vector2 = Vector2(-1.0, 1.0)
@export var temperature_range: Vector2 = Vector2(-1.0, 1.0)
@export var difficulty_range: Vector2 = Vector2(-1.0, 1.0)
@export var features: Array[FeatureGenParams] = []