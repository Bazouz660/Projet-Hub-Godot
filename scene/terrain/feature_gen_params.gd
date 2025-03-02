extends Resource
class_name FeatureGenParams

@export var feature: Feature
@export var density: float = 1.0

@export_group("Noise")
@export var spawn_noise: FastNoiseLite = null
@export var spawn_noise_threshold: float = 0.5
@export var patch_mask_noise: FastNoiseLite = null
@export var patch_mask_threshold: float = 0.7 # Higher threshold = fewer patches