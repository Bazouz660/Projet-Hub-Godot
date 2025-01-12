extends TorsoPartialMove

@export var left_hand: Marker3D
@export var hand_attachement: PackedScene
@export var drink_time: float = 2.3

var hand_history: Node3D = null
var drank: bool = false

func on_enter_state():
	super.on_enter_state()
	drank = false
	if left_hand.get_child_count() > 0 and left_hand.get_child(0) != null:
		hand_history = left_hand.get_child(0)
		left_hand.remove_child(hand_history)

	var instance = hand_attachement.instantiate()
	instance.scale = Vector3(1.0, 1.0, 1.0) / (humanoid.model as HumanoidModel).skeleton.scale
	left_hand.add_child(instance)

func update(_input: InputPackage, _delta: float):
	if works_longer_than(drink_time) and not drank:
		drank = true
		var item = ItemRegistry.get_item_by_id(resources.item_in_use)
		var consumable_component := item.get_component("consumable") as ConsumableItemComponent
		consumable_component.apply_effects(resources)

func on_exit_state():
	super.on_exit_state()
	left_hand.remove_child(left_hand.get_child(0))

	if hand_history != null:
		left_hand.add_child(hand_history)
		hand_history = null
