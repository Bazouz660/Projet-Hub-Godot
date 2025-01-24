extends RefCounted
class_name OBB

var center: Vector3
var half_extents: Vector3
var basis: Basis

func _init(p_center: Vector3, p_half_extents: Vector3, p_basis: Basis):
    center = p_center
    half_extents = p_half_extents
    basis = p_basis

func get_transformed_point(point: Vector3) -> Vector3:
    # Transform point to local space
    var local_point = point - center
    # Apply inverse transformation
    return basis.inverse() * local_point