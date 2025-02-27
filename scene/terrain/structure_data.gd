extends Resource
class_name StructureData

@export var size: Vector3 = Vector3.ZERO
@export var position: Vector3 = Vector3.ZERO
@export var local_pos: Vector3 = Vector3.ZERO

# Add rotation info for when structure is instantiated
@export var rotation_degrees: Vector3 = Vector3.ZERO

# Add type information for structure variants
@export var structure_scene: PackedScene

# Add a unique ID for comparison and dictionary usage
var unique_id: int = 0

func _init():
    # Generate a unique ID for this structure data
    unique_id = randi()

func _to_string():
    return "size: %s, position: %s" % [size, position]

# For dictionary key usage
func hash():
    return unique_id

# For dictionary comparison
func operator_equals(other):
    if other is StructureData:
        return unique_id == other.unique_id
    return false