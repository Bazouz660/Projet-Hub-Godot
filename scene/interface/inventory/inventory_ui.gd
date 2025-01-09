extends Control

@onready var _grid_container: GridContainer = %GridContainer
@onready var _slot_ui: PackedScene = preload("res://scene/interface/inventory/slot_ui.tscn")
@onready var _item_stack_ui: PackedScene = preload("res://scene/interface/inventory/item_stack_ui.tscn")
@export var inventory_component: InventoryComponent

var _slots: Array[SlotUI] = []
static var _selected_item_stack: ItemStackUI = null
static var inventories: Array[Control] = []
static var _hovering_inventory_static: bool = true
var _hovering_inventory: bool = false

func _ready() -> void:
	if inventory_component:
		_setup_inventory()
		inventories.append(self)

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		if inventories.find(self) == -1:
			inventories.append(self)
	else:
		inventories.erase(self)

func _setup_inventory() -> void:
	_setup_slots()
	_update_slots()
	_connect_signals()

	# Example of adding initial items with IDs
	#inventory_component.add_item_by_id("potion_health", 5)
	#inventory_component.add_item_by_id("sword")

func _process(_delta: float) -> void:
	if _selected_item_stack:
		_selected_item_stack.global_position = get_global_mouse_position() + _selected_item_stack.item_icon.size

func _setup_slots() -> void:
	for i in range(inventory_component.max_slots):
		var slot = _slot_ui.instantiate()
		_grid_container.add_child(slot)
		slot.slot_clicked.connect(_on_slot_clicked)
		_slots.append(slot)

func _connect_signals() -> void:
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	self.visibility_changed.connect(_on_visibility_changed)

	inventory_component.item_removed.connect(_on_removed_item)
	inventory_component.inventory_changed.connect(_update_slots)

func _update_hovering_state() -> void:
	for inventory in inventories:
		if inventory._hovering_inventory:
			_hovering_inventory_static = true
			return
	_hovering_inventory_static = false

func _on_mouse_entered() -> void:
	_hovering_inventory = true
	_update_hovering_state()

func _on_mouse_exited() -> void:
	_hovering_inventory = false
	_update_hovering_state()

func _on_removed_item(_item_stack: ItemStack) -> void:
	_update_slots()

func _update_slots() -> void:
	for i in range(_slots.size()):
		_slots[i].item_stack = inventory_component.slots[i]

func _bind_selected_stack(stack: ItemStack) -> void:
	if _selected_item_stack:
		_selected_item_stack.queue_free()
	_selected_item_stack = _item_stack_ui.instantiate()
	add_child(_selected_item_stack)
	_selected_item_stack.item_stack = stack
	inventory_component.content.item_stacks.erase(stack)

func _on_slot_clicked(slot: SlotUI) -> void:
	var slot_index = _slots.find(slot)
	if not _selected_item_stack:
		if inventory_component.slots[slot_index]:
			_select_item_from_slot(slot, slot_index)
	else:
		_handle_item_stack_placement(slot, slot_index)

func _select_item_from_slot(slot: SlotUI, slot_index: int) -> void:
	if inventory_component.slots[slot_index]:
		var item_stack = inventory_component.slots[slot_index]
		inventory_component.slots[slot_index] = null
		_bind_selected_stack(item_stack)
		slot.item_stack = null

func _handle_item_stack_placement(slot: SlotUI, slot_index: int) -> void:
	if inventory_component.slots[slot_index]:
		_handle_slot_with_existing_item_stack(slot_index)
	else:
		_place_selected_item_stack_in_empty_slot(slot, slot_index)

func _handle_slot_with_existing_item_stack(to_slot_index: int) -> void:
	var selected_item_stack = _selected_item_stack.item_stack
	var target_item_stack = inventory_component.slots[to_slot_index]

	if _can_merge_stacks(selected_item_stack, target_item_stack):
		_merge_item_stacks(to_slot_index)
	else:
		_swap_item_stacks(to_slot_index)

func _can_merge_stacks(selected_stack: ItemStack, target_stack: ItemStack) -> bool:
	if selected_stack.item_id != target_stack.item_id:
		return false
	var item = ItemRegistry.get_item_by_id(selected_stack.item_id)
	return item.is_stackable and target_stack.can_add(selected_stack.quantity)

func _merge_item_stacks(to_slot_index: int) -> void:
	var target_stack = inventory_component.slots[to_slot_index]
	target_stack.add(_selected_item_stack.item_stack.quantity)
	_selected_item_stack.queue_free()
	_selected_item_stack = null
	_update_slots()

func _swap_item_stacks(to_slot_index: int) -> void:
	var from_stack = _selected_item_stack.item_stack
	var to_stack = inventory_component.slots[to_slot_index]

	# Update slot indices
	from_stack.slot_index = to_slot_index
	to_stack.slot_index = from_stack.slot_index

	# Swap the stacks in the inventory
	inventory_component.slots[to_slot_index] = from_stack
	inventory_component.content.item_stacks.append(from_stack)

	_selected_item_stack.queue_free()
	_selected_item_stack = null
	_bind_selected_stack(to_stack)

func _place_selected_item_stack_in_empty_slot(slot: SlotUI, slot_index: int) -> void:
	_selected_item_stack.item_stack.slot_index = slot_index
	inventory_component.slots[slot_index] = _selected_item_stack.item_stack
	inventory_component.content.item_stacks.append(_selected_item_stack.item_stack)
	slot.item_stack = _selected_item_stack.item_stack
	_selected_item_stack.queue_free()

func _input(event: InputEvent) -> void:
	if (_selected_item_stack != null and !_hovering_inventory_static
		and inventory_component.is_dropping_enabled
		and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed):

		var drop_position = _get_drop_position()
		var item_stack = _selected_item_stack.item_stack

		# Drop the item at the calculated position
		inventory_component.spawn_item(
			item_stack.item_id,
			item_stack.quantity,
			drop_position
		)

		# Clean up the UI
		_selected_item_stack.queue_free()
		_selected_item_stack = null

		# Emit inventory changed signal to update UI
		inventory_component.inventory_changed.emit()

func _get_drop_position() -> Vector3:
	return inventory_component.global_position
