extends Node3D
class_name DroppedItem

var _item: InventoryItem
var _item_visuals: Node3D = null

@onready var _interact_area: Area3D = $InteractArea

func _ready():
	# Set the item visuals to be the child of this node
	if _item_visuals != null:
		add_child(_item_visuals)
		_item_visuals.name = "ItemVisuals"

	# Connect the interact area signal
	_interact_area.area_entered.connect(_on_interact_area_entered)
	_interact_area.area_exited.connect(_on_interact_area_exited)

static func create(item: InventoryItem, at: Vector3) -> DroppedItem:
	var dropped_item = load("res://scene/item/dropped/dropped_item.tscn").instantiate()
	dropped_item.name = item._prototype._id + "_" + str(Time.get_ticks_msec())
	dropped_item._item = item

	var visuals_loaded = dropped_item._load_item_visuals(item)

	if !visuals_loaded:
		push_warning("Failed to load item visuals for: ", item._prototype._id)

	var level_node = MultiplayerManager.get_level_node()

	var dropped_items_node = level_node.get_node_or_null("DroppedItems")
	if dropped_items_node == null:
		dropped_items_node = Node3D.new()
		dropped_items_node.name = "DroppedItems"
		level_node.add_child(dropped_items_node)
	dropped_item.position = at

	dropped_items_node.add_child(dropped_item)

	return dropped_item

func _load_item_visuals(item: InventoryItem) -> bool:
	if item.get_property("model") == null:
		push_warning("Item has no model property: ", item._prototype._id)
		return false

	var visuals_propety := ""
	if item.get_property("model")["dropped_visuals_path"] == null:
		if item.get_property("model")["visuals_path"] == null:
			push_warning("Item has no visuals path: ", item._prototype._id)
			return false
		else:
			visuals_propety = "visuals_path"
	else:
		visuals_propety = "dropped_visuals_path"

	if visuals_propety == "":
		push_warning("Item has no visuals property: ", item._prototype._id)
		return false

	var visuals_path = item.get_property("model")[visuals_propety]
	var visuals_scene = load(visuals_path)
	if visuals_scene == null:
		push_warning("Visuals scene not found: ", visuals_path)
		return false

	var visuals = visuals_scene.instantiate()
	if visuals == null:
		push_warning("Visuals scene instantiation failed: ", visuals_path)
		return false

	# Set the visuals to be the child of this node
	_item_visuals = visuals
	_item_visuals.name = "ItemVisuals"

	return true

func _on_interact_area_entered(area: Area3D) -> void:
	if area.is_in_group("player"):
		# Call the drop item function on the player
		MultiplayerManager.active_player.interact_area.interacted.connect(_on_interact_area_interacted)

func _on_interact_area_exited(area: Area3D) -> void:
	if area.is_in_group("player"):
		# Disconnect the signal when the player exits the area
		MultiplayerManager.active_player.interact_area.interacted.disconnect(_on_interact_area_interacted)

func _on_interact_area_interacted(player: Player) -> void:
	print("Player interacted with dropped item: ", _item._prototype._id)

	# Pick up the item
	var can_add_item = player.resources.inventory.can_add_item(_item)
	if !can_add_item:
		print("Inventory is full, cannot pick up item: ", _item._prototype._id)
		return

	player.resources.inventory.add_item_autosplitmerge(_item)
	queue_free()
