extends Resource
class_name Feature

enum FeatureType {
    INSTANCE,
    MULTIMESH,
}

@export var label: String

@export_group("Instancing type")
@export var type: FeatureType = FeatureType.INSTANCE

@export_subgroup("Instance")
@export var scene: PackedScene

@export_subgroup("Multimesh")
@export var mesh: Mesh
@export var cast_shadow: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.ShadowCastingSetting.SHADOW_CASTING_SETTING_OFF
@export var receive_biome_color: bool
@export var shader_parameter_color_name: String = "albedo"

@export_group("Randomization")
@export var random_scale: Vector2 = Vector2(1, 1)
@export var random_rotation: Vector2
@export var random_offset: Vector3
@export var follow_normals: bool
