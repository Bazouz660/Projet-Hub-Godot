extends Control

@onready var _grid_container: GridContainer = $GridContainer
@onready var _slot_ui: PackedScene = preload("res://scene/interface/inventory/slot_ui.tscn")
@onready var _item_stack_ui: PackedScene = preload("res://scene/interface/inventory/item_stack_ui.tscn")
@export var inventory_component: InventoryComponent

var _slots: Array[SlotUI] = []
static var _selected_item_stack: ItemStackUI

func _ready() -> void:
	if not inventory_component:
		printerr("InventoryComponent not set in InventoryUI")
		return
	_setup_slots()
	_update_slots()
	_connect_signals()

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
	inventory_component.item_removed.connect(_on_removed_item)
	inventory_component.inventory_changed.connect(_update_slots)

func _on_removed_item(item_stack: ItemStack) -> void:
	if not inventory_component.items.has(item_stack):
		for slot in _slots:
			if slot.item_stack == item_stack:
				slot.item_stack_ui.clear()

func _update_slots() -> void:
	for item_stack in inventory_component.items:
		_assign_item_stack_to_slot(item_stack)

	for slot in _slots:
		slot.update_display()

func _assign_item_stack_to_slot(item_stack: ItemStack) -> void:
	var assigned_slot = _find_slot_with_item_stack(item_stack)
	if not assigned_slot:
		var empty_slot = _find_empty_slot()
		if empty_slot:
			empty_slot.item_stack = item_stack

func _find_slot_with_item_stack(item_stack: ItemStack) -> SlotUI:
	for slot in _slots:
		if slot.item_stack == item_stack:
			return slot
	return null

func _find_empty_slot() -> SlotUI:
	for slot in _slots:
		if slot.item_stack == null:
			return slot
	return null

func _bind_selected_stack(stack: ItemStack) -> void:
	if _selected_item_stack:
		_selected_item_stack.queue_free()
	_selected_item_stack = _item_stack_ui.instantiate()
	add_child(_selected_item_stack)
	_selected_item_stack.item_stack = stack
	inventory_component.items.erase(stack)

func _on_slot_clicked(slot: SlotUI) -> void:
	if not _selected_item_stack:
		_select_item_from_slot(slot)
	else:
		_handle_item_stack_placement(slot)

func _select_item_from_slot(slot: SlotUI) -> void:
	if slot.item_stack:
		_bind_selected_stack(slot.item_stack)
		slot.item_stack = null

func _handle_item_stack_placement(slot: SlotUI) -> void:
	if slot.item_stack:
		_handle_slot_with_existing_item_stack(slot)
	else:
		_place_selected_item_stack_in_empty_slot(slot)

func _handle_slot_with_existing_item_stack(slot: SlotUI) -> void:
	var selected_item_stack = _selected_item_stack.item_stack
	var target_item_stack = slot.item_stack
	
	if _can_merge_stacks(selected_item_stack, target_item_stack):
		_merge_item_stacks(slot)
	else:
		_swap_item_stacks(slot)

func _can_merge_stacks(selected_stack: ItemStack, target_stack: ItemStack) -> bool:
	return (selected_stack.item == target_stack.item and 
			target_stack.item.is_stackable and 
			target_stack.can_add(selected_stack.quantity))

func _merge_item_stacks(slot: SlotUI) -> void:
	slot.item_stack.add(_selected_item_stack.item_stack.quantity)
	_selected_item_stack.queue_free()
	_selected_item_stack = null
	_update_slots()

func _swap_item_stacks(slot: SlotUI) -> void:
	var temp = slot.item_stack
	slot.item_stack = _selected_item_stack.item_stack
	inventory_component.items.append(_selected_item_stack.item_stack)
	_selected_item_stack.queue_free()
	_selected_item_stack = null
	_bind_selected_stack(temp)

func _place_selected_item_stack_in_empty_slot(slot: SlotUI) -> void:
	slot.item_stack = _selected_item_stack.item_stack
	inventory_component.items.append(slot.item_stack)
	_selected_item_stack.queue_free()
	_selected_item_stack = null
