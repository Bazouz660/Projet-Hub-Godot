@tool
extends Node3D
class_name DebugRegionVisualizer

@export var structure_manager: StructureManager
@export var enabled: bool = false:
    set(value):
        if enabled != value:
            enabled = value
            _update_visibility()

var region_markers = {}
var region_size = 256.0 # Must match StructureManager.region_size

func _ready():
    if not Engine.is_editor_hint():
        # Create a timer to periodically update visualizations
        var timer = Timer.new()
        timer.wait_time = 1.0
        timer.one_shot = false
        timer.timeout.connect(_update_regions)
        add_child(timer)
        timer.start()

func _update_regions():
    if not enabled or not structure_manager:
        return

    # Clear old markers that are no longer generated
    var regions_to_remove = []
    for region in region_markers.keys():
        if not structure_manager.generated_regions.has(region):
            regions_to_remove.append(region)

    for region in regions_to_remove:
        region_markers[region].queue_free()
        region_markers.erase(region)

    # Add new markers
    for region in structure_manager.generated_regions:
        if not region_markers.has(region):
            _create_region_marker(region)

func _create_region_marker(region: Vector2):
    var marker = MeshInstance3D.new()
    var mesh = PlaneMesh.new()
    mesh.size = Vector2(region_size, region_size)
    marker.mesh = mesh

    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0, 1, 0, 0.2) # Green with transparency
    material.flags_transparent = true
    material.flags_unshaded = true
    marker.material_override = material

    # Position at region center, slightly above terrain
    var x = region.x * region_size + (region_size * 0.5)
    var z = region.y * region_size + (region_size * 0.5)
    var height = TerrainChunkNoise.sample_height(x, z) + 5.0

    add_child(marker)
    marker.global_position = Vector3(x, height, z)
    region_markers[region] = marker

func _update_visibility():
    for marker in region_markers.values():
        marker.visible = enabled