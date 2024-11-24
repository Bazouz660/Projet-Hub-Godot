extends Move
class_name Slash1

@export var TRANSITION_TIMING = 1.6 # Full animation duration
@export var COMBO_TIMING = 1.1 # Time at which we can chain the attack
@export var hit_damage = 20 # will be a function of player stats in the future

func on_enter_state():
	player.velocity = Vector3.ZERO
	player.stamina.use_stamina(stamina_required)

func default_lifecycle(input : InputPackage) -> String:
	if works_longer_than(COMBO_TIMING) and has_queued_move:
		has_queued_move = false
		return queued_move
	elif works_longer_than(TRANSITION_TIMING):
		input.actions.sort_custom(moves_priority_sort)
		return input.actions[0]
	else:
		return "ok"

func update(input : InputPackage, delta):
	if works_between(0.0, 1.6):
		player.model.active_weapon.is_attacking = true
	else:
		player.model.active_weapon.is_attacking = false

func form_hit_data(weapon : Weapon) -> HitData:
	var hit = HitData.new()
	hit.damage = hit_damage
	hit.hit_move_animation = animation
	hit.is_parryable = is_parryable()
	hit.weapon = player.model.active_weapon
	return hit

func on_exit_state():
	player.model.active_weapon.hitbox_ignore_list.clear()
	player.model.active_weapon.is_attacking = false
