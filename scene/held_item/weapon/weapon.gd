extends Area3D
class_name Weapon

var hitbox_ignore_list: Array[Area3D]
var is_attacking: bool = false

var item: InventoryItem
@export var holder: HumanoidModel

var damage: float = 0.0

func get_hit_data() -> HitData:
	return holder.current_move.form_hit_data(self)
