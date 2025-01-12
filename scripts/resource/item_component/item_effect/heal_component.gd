extends ItemEffectComponent
class_name HealComponent

@export var heal_amount: float = 10

func apply_effect(_target) -> void:
    _target.gain_health(heal_amount)