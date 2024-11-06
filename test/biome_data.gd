# biome_data.gd
class_name BiomeData
extends Resource

@export var name: String
@export var color: Color
@export var features: Array[BiomeFeature]
@export var height_multiplication: float = 1.0  # Modify base height for this biome
@export_range(0, 1) var max_slope: float = 1.0  # Maximum slope for feature placement
