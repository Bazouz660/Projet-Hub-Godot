extends Node
class_name HumanoidCombat

@onready var model = $".." as HumanoidModel

var events_buffer: Array[String] = []

static var inputs_priority: Dictionary = {
	"light_attack_pressed": 1,
	"heavy_attack_pressed": 2,
}

func contextualize(new_input: InputPackage) -> InputPackage:
	translate_inputs(new_input)
	new_input.triggered_reactions.append_array(events_buffer)
	return new_input


func translate_inputs(input: InputPackage):
	if not input.combat_actions.is_empty():
		input.combat_actions.sort_custom(combat_action_priority_sort)
		var best_input_action: String = input.combat_actions[0]
		var weapon_component = model.resources.right_hand_slot.get_component("weapon")
		if weapon_component == null:
			push_error("No weapon equipped.")
			return
		var translated_into_move_name: String = weapon_component.basic_attacks[best_input_action]
		input.actions.append(translated_into_move_name)


static func combat_action_priority_sort(a: String, b: String):
	return inputs_priority[a] > inputs_priority[b]
