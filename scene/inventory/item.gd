extends Resource
class_name Item

@export var name: String = ""
@export var dimensions: Vector2i = Vector2i(1, 1)
@export var texture: Texture2D = null
@export var is_stackable: bool = false
@export var max_stack_size: int = 1  # Default to 1 for non-stackable items

func _init(p_name: String = "", p_dimensions: Vector2i = Vector2i(1, 1), p_texture: Texture2D = null, p_is_stackable: bool = false, p_max_stack_size: int = 1):
	name = p_name
	dimensions = p_dimensions
	texture = p_texture
	is_stackable = p_is_stackable
	max_stack_size = p_max_stack_size
