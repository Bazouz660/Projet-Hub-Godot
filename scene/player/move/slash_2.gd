extends Move
class_name Slash2

@export var TRANSITION_TIMING = 0.8333
@export var COMBO_TIMING = 0.5
@export var animation_length : float = 3
@export var hit_damage = 20 # will be a function of player stats in the future

func on_enter_state():
	player.stamina.use_stamina(stamina_required)

func default_lifecycle(input : InputPackage):
	if works_longer_than(COMBO_TIMING) and has_queued_move:
		has_queued_move = false
		return queued_move
	elif works_longer_than(TRANSITION_TIMING):
		input.actions.sort_custom(moves_priority_sort)
		return input.actions[0]
	else:
		return "ok"


func update(input : InputPackage, float):
	if works_between(0.25, 0.44):
		player.model.active_weapon.is_attacking = true
	else:
		player.model.active_weapon.is_attacking = false


func form_hit_data(weapon : Weapon) -> HitData:
	var hit = HitData.new()
	hit.damage = hit_damage
	hit.hit_move_animation = animation
	hit.is_parryable = is_parryable()
	hit.weapon = player.model.active_weapon
	print("pipi")
	return hit


func on_exit_state():
	player.model.active_weapon.hitbox_ignore_list.clear()
	player.model.active_weapon.is_attacking = false
