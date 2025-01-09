extends Node3D
class_name InventoryComponent

signal item_added(item_stack: ItemStack)
signal item_removed(item_stack: ItemStack)
signal inventory_full
signal inventory_changed

@export var max_slots: int = 20
@export var is_dropping_enabled: bool = false

var content: InventoryContent = InventoryContent.new()
var slots: Array[ItemStack] = [] # Array of size max_slots, null means empty slot

static var dropped_item_scene: PackedScene = preload("res://scene/item/dropped_item/dropped_item.tscn")

func _ready() -> void:
	# Initialize slots array
	slots.resize(max_slots)
	slots.fill(null)

func find_first_empty_slot() -> int:
	for i in range(slots.size()):
		if slots[i] == null:
			return i
	return -1

func add_item_by_id(item_id: String, quantity: int = 1) -> int:
	# First try to stack with existing items
	for existing_stack in content.item_stacks:
		if existing_stack.item_id == item_id:
			var item = ItemRegistry.get_item_by_id(item_id)
			if item.is_stackable and existing_stack.can_add(quantity):
				var remaining = existing_stack.add(quantity)
				if remaining == 0:
					item_added.emit(existing_stack)
					inventory_changed.emit()
					return existing_stack.slot_index
				quantity = remaining

	# If we couldn't stack or have remaining quantity, create new stack
	var empty_slot_index = find_first_empty_slot()
	if empty_slot_index != -1:
		var item = ItemRegistry.get_item_by_id(item_id)
		var new_stack = ItemStack.new(item_id, quantity, item.max_stack_size, empty_slot_index)
		if !item.is_stackable:
			new_stack.quantity = 1
		content.item_stacks.append(new_stack)
		slots[empty_slot_index] = new_stack
		item_added.emit(new_stack)
		inventory_changed.emit()
		return empty_slot_index

	inventory_full.emit()
	return -1

func remove_item_from_slot(slot_index: int, quantity: int = 1) -> bool:
	print("Removing " + str(quantity) + " items from slot " + str(slot_index))
	var item_stack = slots[slot_index]
	if item_stack == null:
		print("Slot is null")
		return false

	var removed = item_stack.remove(quantity)
	print("Removing " + str(removed) + " items")
	if removed > 0:
		if item_stack.quantity <= 0:
			print("Removing item stack")
			content.item_stacks.erase(item_stack)
			slots[slot_index] = null
		item_removed.emit(item_stack)
		inventory_changed.emit()
		print(str(removed) + " item(s) removed")
		return true
	print("Failed to remove items")
	return false

func spawn_item(item_id: String, quantity: int, p_position: Vector3) -> void:
	if MultiplayerManager.is_host:
		_spawn_item(item_id, quantity, p_position)
	else:
		_spawn_item.rpc_id(1, item_id, quantity, p_position)

@rpc("any_peer", "call_remote", "reliable")
func _spawn_item(item_id: String, quantity: int, p_position: Vector3) -> void:
	var item_instance = dropped_item_scene.instantiate() as DroppedItem
	item_instance.set_multiplayer_authority(1, true)
	item_instance.name = item_id + "?" + str(quantity) + "?" + str(item_instance.get_instance_id())
	SceneManager.current_3d_scene.add_child(item_instance)
	item_instance.rpc_init.rpc(item_id, quantity, ItemRegistry.get_item_by_id(item_id).name, p_position)
	print("Item spawned at " + str(p_position) + " in node " + str(SceneManager.current_3d_scene.name))

func get_item_quantity(item_id: String) -> int:
	var total_quantity = 0
	for item_stack in content.item_stacks:
		if item_stack.item_id == item_id:
			total_quantity += item_stack.quantity
	return total_quantity

func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_item_quantity(item_id) >= quantity

func move_item(from_slot: int, to_slot: int) -> void:
	if from_slot < 0 or from_slot >= max_slots or to_slot < 0 or to_slot >= max_slots:
		return

	var temp = slots[to_slot]
	slots[to_slot] = slots[from_slot]
	slots[from_slot] = temp

	if slots[to_slot]:
		slots[to_slot].slot_index = to_slot
	if slots[from_slot]:
		slots[from_slot].slot_index = from_slot

	inventory_changed.emit()

func save_inventory() -> void:
	print("Saving test inventory")

	content.slot_indices.resize(content.item_stacks.size())
	content.item_ids.resize(content.item_stacks.size())
	content.quantities.resize(content.item_stacks.size())
	content.max_stack_sizes.resize(content.item_stacks.size())

	for i in range(content.item_stacks.size()):
		content.slot_indices[i] = content.item_stacks[i].slot_index
		content.item_ids[i] = content.item_stacks[i].item_id
		content.quantities[i] = content.item_stacks[i].quantity
		content.max_stack_sizes[i] = content.item_stacks[i].max_stack_size
	ResourceSaver.save(content, "user://test.tres")

func load_inventory() -> void:
	print("Loading test inventory")
	if ResourceLoader.exists("user://test.tres"):
		var res = ResourceLoader.load("user://test.tres")
		if res == null or not res is InventoryContent:
			print("Failed to load test inventory")
			return
		print("Test inventory loaded: ")
		for i in range(res.item_ids.size()):
			var slot = add_item_by_id(res.item_ids[i], res.quantities[i])
			if slot != -1:
				move_item(slot, res.slot_indices[i])

		inventory_changed.emit()

	else:
		print("No test inventory file found")
