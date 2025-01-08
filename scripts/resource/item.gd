extends Resource
class_name Item

@export var id: String
@export var name: String
@export var description: String
@export var is_stackable: bool = false
@export var max_stack_size: int = 1
@export var icon: Texture2D
@export var model: PackedScene
@export var components: Array[ItemComponent] = []

func has_component(component_type: String) -> bool:
    for component in components:
        if component.component_type == component_type:
            return true
    return false

func get_component(component_type: String) -> ItemComponent:
    for component in components:
        if component.component_type == component_type:
            return component
    return null

func get_component_index(component_type: String) -> int:
    for i in range(components.size()):
        if components[i].component_type == component_type:
            return i
    return -1

func add_component(component: ItemComponent) -> void:
    components.append(component)

func remove_component(component_type: String) -> void:
    var index = get_component_index(component_type)
    if index != -1:
        components.remove_at(index)
