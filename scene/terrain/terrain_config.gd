extends Resource
class_name TerrainConfig

signal debug_toggled(state: bool)
signal view_distance_changed(value: int)

@export var chunk_size: int = 16
@export var vertex_per_meter: int = 4

@export var view_distance: int = 3:
	set(value):
		if value != view_distance:
			view_distance = value
			view_distance_changed.emit(value)

@export var update_rate: float = 1.0
@export var world_seed: int = 0
@export var max_threads: int = 4

@export var height_scale: float = 1.0

@export var continentalness: FastNoiseLite
@export var continentalness_curve: Curve

@export var peaks_and_valeys: FastNoiseLite
@export var peaks_and_valeys_curve: Curve

@export var erosion: FastNoiseLite
@export var erosion_curve: Curve

@export var humidity: FastNoiseLite
@export var temperature: FastNoiseLite
@export var difficulty: FastNoiseLite

@export var material: Material
@export var chunk_borders_material: Material

@export var show_chunk_borders: bool = false:
	set(value):
		if value != show_chunk_borders:
			show_chunk_borders = value
			debug_toggled.emit(value)

@export var water_material: Material
@export var sea_level: float = 0.0

@export var biomes: Array[Biome] = []

static var biomes_label_index: Dictionary[String, Biome] = {}
static var biomes_index_label: Dictionary[int, Biome] = {}

func setup():
	continentalness.seed = world_seed
	peaks_and_valeys.seed = world_seed + 1
	erosion.seed = world_seed + 2
	humidity.seed = world_seed + 3
	temperature.seed = world_seed + 4
	difficulty.seed = world_seed + 5

	_generate_biomes_ids()
	_build_biomes_index()

func _generate_biomes_ids():
	for i in range(biomes.size()):
		biomes[i].id = i

func _build_biomes_index():
	for i in range(biomes.size()):
		biomes_label_index[biomes[i].label] = biomes[i]
		biomes_index_label[biomes[i].id] = biomes[i]