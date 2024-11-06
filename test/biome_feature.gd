class_name BiomeFeature
extends Resource

enum SpawnMethod { INSTANCE, MULTIMESH }

@export var scene_or_mesh: Resource  # Can be either PackedScene or Mesh
@export var spawn_method: SpawnMethod
@export_range(0, 100) var density: float = 10.0
@export var min_scale: float = 0.8
@export var max_scale: float = 1.2
@export var use_noise_distribution: bool = false
@export var distribution_noise_scale: float = 1.0  # Only used if use_noise_distribution is true
@export var align_to_normal: bool = false  # Align feature to terrain normal
