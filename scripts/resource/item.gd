extends Resource
class_name Item

@export var id: String
@export var name: String
@export var description: String
@export var is_stackable: bool = false
@export var max_stack_size: int = 1
@export var icon: Texture2D

func _init(p_id: String = "", p_name: String = "", p_description: String = "", p_is_stackable: bool = false, p_max_stack_size: int = 1) -> void:
    id = p_id
    name = p_name
    description = p_description
    is_stackable = p_is_stackable
    max_stack_size = p_max_stack_size