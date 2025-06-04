class_name AnimationLayer
extends Node

enum BoneName {
	ROOT,
	HIPS,
	SPINE,
	CHEST,
	UPPER_CHEST,
	NECK,
	HEAD,
	LEFT_EYE,
	RIGHT_EYE,
	JAW,
	LEFT_SHOULDER,
	LEFT_UPPER_ARM,
	LEFT_LOWER_ARM,
	LEFT_HAND,
	LEFT_THUMB_METACARPAL,
	LEFT_THUMB_PROXIMAL,
	LEFT_THUMB_DISTAL,
	LEFT_INDEX_PROXIMAL,
	LEFT_INDEX_INTERMEDIATE,
	LEFT_INDEX_DISTAL,
	LEFT_MIDDLE_PROXIMAL,
	LEFT_MIDDLE_INTERMEDIATE,
	LEFT_MIDDLE_DISTAL,
	LEFT_RING_PROXIMAL,
	LEFT_RING_INTERMEDIATE,
	LEFT_RING_DISTAL,
	LEFT_LITTLE_PROXIMAL,
	LEFT_LITTLE_INTERMEDIATE,
	LEFT_LITTLE_DISTAL,
	RIGHT_SHOULDER,
	RIGHT_UPPER_ARM,
	RIGHT_LOWER_ARM,
	RIGHT_HAND,
	RIGHT_THUMB_METACARPAL,
	RIGHT_THUMB_PROXIMAL,
	RIGHT_THUMB_DISTAL,
	RIGHT_INDEX_PROXIMAL,
	RIGHT_INDEX_INTERMEDIATE,
	RIGHT_INDEX_DISTAL,
	RIGHT_MIDDLE_PROXIMAL,
	RIGHT_MIDDLE_INTERMEDIATE,
	RIGHT_MIDDLE_DISTAL,
	RIGHT_RING_PROXIMAL,
	RIGHT_RING_INTERMEDIATE,
	RIGHT_RING_DISTAL,
	RIGHT_LITTLE_PROXIMAL,
	RIGHT_LITTLE_INTERMEDIATE,
	RIGHT_LITTLE_DISTAL,
	LEFT_UPPER_LEG,
	LEFT_LOWER_LEG,
	LEFT_FOOT,
	LEFT_TOES,
	RIGHT_UPPER_LEG,
	RIGHT_LOWER_LEG,
	RIGHT_FOOT,
	RIGHT_TOES
}

static var bone_names: Array[String]
static var bone_lookup_table: Dictionary[String, BoneName] = {}

@export var animation: String
@export_range(0, 1.0, 0.01) var weight: float = 1.0
@export var mask: Array[BoneName] = []

static func _init_bone_names() -> void:
    bone_names = [
        "Root", "Hips", "Spine", "Chest", "UpperChest", "Neck", "Head",
        "LeftEye", "RightEye", "Jaw", "LeftShoulder", "LeftUpperArm",
        "LeftLowerArm", "LeftHand", "LeftThumbMetacarpal", "LeftThumbProximal",
        "LeftThumbDistal", "LeftIndexProximal", "LeftIndexIntermediate",
        "LeftIndexDistal", "LeftMiddleProximal", "LeftMiddleIntermediate",
        "LeftMiddleDistal", "LeftRingProximal", "LeftRingIntermediate",
        "LeftRingDistal", "LeftLittleProximal", "LeftLittleIntermediate",
        "LeftLittleDistal", "RightShoulder", "RightUpperArm",
        "RightLowerArm", "RightHand", "RightThumbMetacarpal",
        "RightThumbProximal", "RightThumbDistal", "RightIndexProximal",
        "RightIndexIntermediate", "RightIndexDistal", "RightMiddleProximal",
        "RightMiddleIntermediate", "RightMiddleDistal", "RightRingProximal",
        "RightRingIntermediate", "RightRingDistal", "RightLittleProximal",
        "RightLittleIntermediate", "RightLittleDistal", "LeftUpperLeg",
        "LeftLowerLeg", "LeftFoot", "LeftToes", "RightUpperLeg",
        "RightLowerLeg", "RightFoot", "RightToes"
    ]
    _generate_lookup_table()

static func _generate_lookup_table() -> void:
    # Generate a lookup table that maps a bone name to its index to avoid using find
    if bone_names.is_empty():
        _init_bone_names()
    for i in range(bone_names.size()):
        bone_lookup_table[bone_names[i]] = i as BoneName

static func get_bone_name(bone_name: BoneName) -> String:
    # Initialize bone_names if it's empty (static arrays in Resources don't auto-initialize)
    if bone_names.is_empty():
        _init_bone_names()
    if bone_name < 0 or bone_name >= bone_names.size():
        push_error("Invalid bone name index: " + str(bone_name))
        return ""
    return bone_names[bone_name]

func set_mask_from_string_array(string_mask: Array[String]) -> void:
    if not string_mask:
        return
    if bone_names.is_empty():
        _init_bone_names()
    var new_mask: Array[BoneName] = []
    for bone_name in string_mask:
        if bone_lookup_table.has(bone_name):
            new_mask.append(bone_lookup_table[bone_name])
        else:
            push_error("Bone name not found in lookup table: " + bone_name)
    mask = new_mask