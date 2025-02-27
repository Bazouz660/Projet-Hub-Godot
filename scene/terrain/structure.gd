@tool
extends StaticBody3D
class_name Structure

@export var mesh: MeshInstance3D
@export var data: StructureData
@export_tool_button("Generate Data", "Callable")
var print_action = _generate_data.bind()

var _footprint_mesh: MeshInstance3D

func _ready():
    _footprint_mesh = MeshInstance3D.new()
    add_child(_footprint_mesh)
    if not data:
        _generate_data()
    _generate_footprint_mesh()

func _generate_footprint_mesh():
    var _mesh := PlaneMesh.new()
    _mesh.size = Vector2(data.size.x, data.size.z)
    _footprint_mesh.mesh = _mesh
    var structure_debug_material = StandardMaterial3D.new()
    structure_debug_material.albedo_color = Color(1, 0, 0, 0.2)
    structure_debug_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    structure_debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
    structure_debug_material.no_depth_test = true
    structure_debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _footprint_mesh.material_override = structure_debug_material
    _footprint_mesh.mesh = _mesh
    #_footprint_mesh.visible = false

func _generate_data(_p = ""):
    var aabb := mesh.global_transform * mesh.get_aabb()
    aabb.grow(2.0)
    data = StructureData.new()
    data.size = aabb.size
    data.position = aabb.position
    data.local_pos = aabb.position - global_transform.origin
    _generate_footprint_mesh()

func _exit_tree():
    # Don't unregister the structure data when the instance is removed
    # StructureManager.unregister_structure(data)
    pass