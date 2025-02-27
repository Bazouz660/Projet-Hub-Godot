extends Resource
class_name StructureGenParams

@export var structure: PackedScene
@export var structure_data: StructureData

@export_range(-1.0, 1.0, 0.01) var difficulty_min: float = -1.0
@export_range(-1.0, 1.0, 0.01) var difficulty_max: float = 1.0

# Impacts the loot rarity of the structure (0.0 is default)
@export_range(0.0, 1.0, 0.01) var loot_rarity: float = 0.0

# Impacts the amount of loot in the structure
@export_range(0, 1.0, 0.01) var loot_amount: int = 0

# Impacts the amount of enemies in the structure
@export_range(0, 1.0, 0.01) var danger_level: int = 0

# Sets the structure density
@export_range(0.0, 1.0, 0.01) var density: float = 0.1


# Define biome-specific structure variants
@export var valid_biomes: Array[String] = [
    "Grass Plains",
]
