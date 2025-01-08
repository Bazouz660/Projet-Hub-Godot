extends ItemComponent
class_name WeaponComponent

@export var damage: float = 10
@export var basic_attacks: Dictionary[String, String] = {}

func _init():
    component_type = "weapon"