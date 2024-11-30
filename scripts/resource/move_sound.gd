extends Resource
class_name MoveSound

@export var sound_name: String = ""
## Interval between each sound triggering. If play once is true, it is used as a delay
@export var delay: float = 0.0
@export var play_once: bool = true
@export var material_based: bool = false
