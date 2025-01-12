extends ItemEffectComponent
class_name StaminaGainComponent

@export var amount: float = 10

func apply_effect(_target) -> void:
    _target.gain_stamina(amount)