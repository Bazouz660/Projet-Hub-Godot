extends ItemComponent
class_name ConsumableItemComponent

@export var effects: Array[ItemEffectComponent] = []

func _init():
    component_type = "consumable"
    for effect in effects:
        effect.base_item = base_item

func apply_effects(_target) -> void:
    for effect in effects:
        effect.apply_effect(_target)