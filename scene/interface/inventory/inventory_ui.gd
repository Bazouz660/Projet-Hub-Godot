extends Control

@onready var _grid_container: GridContainer = $GridContainer
@onready var _slot_ui: PackedScene = preload("res://scene/interface/inventory/slot_ui.tscn")
@onready var _item_stack_ui: PackedScene = preload("res://scene/interface/inventory/item_stack_ui.tscn")
@export var inventory_component: InventoryComponent

var _slots: Array[SlotUI] = []
var _selected_item_stack: ItemStackUI

func _ready() -> void:
	if not inventory_component:
		printerr("InventoryComponent not set in InventoryUI")
		return
	_setup_slots()
	_update_slots()
	inventory_component.item_removed.connect(_on_removed_item)
	inventory_component.inventory_changed.connect(_update_slots)

	inventory_component.add_item(preload("res://data/item/potion_health.res"), 5)
	inventory_component.add_item(preload("res://data/item/sword.res"))

func _process(_delta: float) -> void:
	if _selected_item_stack:
		_selected_item_stack.position = get_viewport().get_mouse_position() + Vector2(32, 32)

func _setup_slots() -> void:
	for i in range(inventory_component.max_slots):
		var slot = _slot_ui.instantiate()
		_grid_container.add_child(slot)
		slot.slot_clicked.connect(_on_slot_clicked)
		_slots.append(slot)

func _on_removed_item(item_stack: ItemStack) -> void:
	if not inventory_component.items.has(item_stack):
		for slot in _slots:
			if slot.item_stack == item_stack:
				slot.item_stack_ui.clear()

func _update_slots() -> void:
	for item_stack in inventory_component.items:
		var assigned_slot = false

		for slot in _slots:
			slot.update_display()
			if slot.item_stack == item_stack:
				assigned_slot = true
				break

		if not assigned_slot:
			for slot in _slots:
				if slot.item_stack == null:
					slot.item_stack = item_stack
					assigned_slot = true
					break

func _bind_selected_stack(stack: ItemStack) -> void:
	if _selected_item_stack:
		_selected_item_stack.queue_free()
	_selected_item_stack = _item_stack_ui.instantiate()
	add_child(_selected_item_stack)
	_selected_item_stack.item_stack = stack

func _on_slot_clicked(slot: SlotUI) -> void:
	if not _selected_item_stack:
		if slot.item_stack:
			_bind_selected_stack(slot.item_stack)
			slot.item_stack = null

	else:
		if slot.item_stack:
			if _selected_item_stack.item_stack.item == slot.item_stack.item and slot.item_stack.item.is_stackable:
				if slot.item_stack.can_add(_selected_item_stack.item_stack.quantity):
					slot.item_stack.add(_selected_item_stack.item_stack.quantity)
					_selected_item_stack.queue_free()
					_selected_item_stack = null
					_update_slots()

			else:
				var temp = slot.item_stack
				slot.item_stack = _selected_item_stack.item_stack
				_selected_item_stack.queue_free()
				_selected_item_stack = null
				_bind_selected_stack(temp)

		else:
			slot.item_stack = _selected_item_stack.item_stack
			_selected_item_stack.queue_free()
			_selected_item_stack = null
