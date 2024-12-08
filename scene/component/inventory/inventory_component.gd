extends Node
class_name InventoryComponent

signal item_added(item_stack: ItemStack)
signal item_removed(item_stack: ItemStack)
signal inventory_full
signal inventory_changed

@export var max_slots: int = 20
var items: Array[ItemStack] = []

func add_item(new_item: Item, quantity: int = 1) -> bool:
	for item_stack in items:
		if item_stack.item == new_item and item_stack.can_add(quantity):
			var remaining = item_stack.add(quantity)
			if remaining == 0:
				item_added.emit(item_stack)
				inventory_changed.emit()
				return true
			quantity = remaining

	if items.size() < max_slots:
		var new_stack = ItemStack.new(new_item, quantity)
		if !new_stack.item.is_stackable:
			new_stack.quantity = 1
		items.append(new_stack)
		item_added.emit(new_stack)
		inventory_changed.emit()
		return true

	inventory_full.emit()
	return false

func remove_item(item_to_remove: Item, quantity: int = 1) -> bool:
	
	for i in range(items.size() - 1, -1, -1):
		var item_stack = items[i]
		if item_stack.item == item_to_remove:
			var removed = item_stack.remove(quantity)
			quantity -= removed

			if item_stack.quantity <= 0:
				items.remove_at(i)

			if quantity <= 0:
				item_removed.emit(item_stack)
				inventory_changed.emit()
				return true

	return false

func get_item_quantity(item: Item) -> int:
	var total_quantity = 0
	for item_stack in items:
		if item_stack.item == item:
			total_quantity += item_stack.quantity
	return total_quantity

func has_item(item: Item, quantity: int = 1) -> bool:
	return get_item_quantity(item) >= quantity

func get_total_items() -> int:
	return items.size()

func is_full() -> bool:
	return items.size() >= max_slots

func get_items() -> Array[ItemStack]:
	return items.duplicate()
