# Inventory.gd
extends Node
class_name Inventory

# Signal to notify the GUI when the inventory is updated
signal inventory_updated

# The size of the inventory grid (columns, rows)
@export var grid_size: Vector2i = Vector2i(10, 10)

# Dictionary to store inventory items
# Key: Vector2i position
# Value: InventoryEntry or {"covered": true}
var items: Dictionary = {}

# Define Sorting Criteria Enum
enum SortCriteria {
	NAME,
	TYPE,
	SIZE,
	QUANTITY
}

func _ready():
	# Example items initialization (ensure the paths are correct)
	var apple = load("res://data/item/apple.res") as Item
	var sword = load("res://data/item/sword.res") as Item
	var caca = load("res://data/item/caca.res") as Item

	# Add items to the inventory
	add_item_to_first_available_slot(apple, 10)  # Stackable item with quantity
	add_item_to_first_available_slot(sword)
	add_item_to_first_available_slot(sword)
	add_item_to_first_available_slot(sword)
	add_item_to_first_available_slot(sword)
	add_item_to_first_available_slot(sword)
	add_item_to_first_available_slot(sword)
	add_item_to_first_available_slot(caca, 10)  # Stackable item with quantity
	# Add more items as needed
	sort_inventory(SortCriteria.NAME)

# Adds an item to a specific position with an optional quantity (default is 1)
func add_item(item: Item, position: Vector2i, quantity: int = 1) -> bool:
	if not can_place_item(item, position, quantity):
		return false

	if item.is_stackable:
		_add_stackable_item(item, position, quantity)
	else:
		_add_non_stackable_item(item, position)

	inventory_updated.emit()
	return true

# Internal function to handle adding stackable items
func _add_stackable_item(item: Item, position: Vector2i, quantity: int):
	if items.has(position):
		var existing_entry = items[position] as InventoryEntry
		existing_entry.quantity += quantity
	else:
		items[position] = InventoryEntry.new(item, quantity)

# Internal function to handle adding non-stackable items
func _add_non_stackable_item(item: Item, position: Vector2i):
	for y in range(item.dimensions.y):
		for x in range(item.dimensions.x):
			var pos = Vector2i(position.x + x, position.y + y)
			if x == 0 and y == 0:
				# Top-left cell holds the item data
				items[pos] = InventoryEntry.new(item, 1)
			else:
				# Other cells are marked as covered
				items[pos] = {"covered": true}

# Removes a specified quantity of an item from a given position
# Returns the removed Item or null if removal failed
func remove_item(position: Vector2i, quantity: int = 1) -> Item:
	if not items.has(position):
		return null

	var entry = items[position]
	if not (entry is InventoryEntry):
		return null

	var item = entry.item

	if item.is_stackable:
		_remove_stackable_item(entry, position, quantity)
	else:
		_remove_non_stackable_item(item, position)

	inventory_updated.emit()
	return item

# Internal function to handle removing stackable items
func _remove_stackable_item(entry: InventoryEntry, position: Vector2i, quantity: int):
	entry.quantity -= quantity
	if entry.quantity <= 0:
		items.erase(position)

# Internal function to handle removing non-stackable items
func _remove_non_stackable_item(item: Item, position: Vector2i):
	for y in range(item.dimensions.y):
		for x in range(item.dimensions.x):
			var pos = Vector2i(position.x + x, position.y + y)
			if items.has(pos):
				items.erase(pos)


# Determines if an item can be placed at a specific position with an optional quantity
func can_place_item(item: Item, position: Vector2i, quantity: int = 1) -> bool:
	# Check inventory boundaries
	if not _is_within_bounds(item, position):
		return false

	if item.is_stackable:
		return _can_place_stackable(item, position, quantity)
	else:
		return _can_place_non_stackable(item, position)
		
# Internal function to check boundaries
func _is_within_bounds(item: Item, position: Vector2i) -> bool:
	return (position.x >= 0 and position.y >= 0 and 
		   position.x + item.dimensions.x <= grid_size.x and 
		   position.y + item.dimensions.y <= grid_size.y)

# Internal function to handle placement of stackable items
func _can_place_stackable(item: Item, position: Vector2i, quantity: int) -> bool:
	if items.has(position):
		var existing_entry = items[position]
		if existing_entry is InventoryEntry:
			if existing_entry.item != item:
				return false
			if existing_entry.quantity + quantity > item.max_stack_size:
				return false
			return true
		else:
			# Position is covered by a multi-cell item; cannot stack here
			return false
	else:
		# Position is empty; can place the stackable item here
		return true

# Internal function to handle placement of non-stackable items
func _can_place_non_stackable(item: Item, position: Vector2i) -> bool:
	for y in range(item.dimensions.y):
		for x in range(item.dimensions.x):
			var pos = Vector2i(position.x + x, position.y + y)
			if items.has(pos):
				return false
	return true
	
# Moves a specified quantity of an item from one position to another
# For non-stackable items, quantity is ignored and the entire item is moved
# Returns true if the move was successful, false otherwise
func move_item(from_position: Vector2i, to_position: Vector2i, quantity: int = 1) -> bool:
	if not items.has(from_position):
		print("No item at the source position.")
		return false

	var entry = items[from_position]
	
	if entry is InventoryEntry:
		var item = entry.item
		if item.is_stackable:
			if quantity < 1 or quantity > entry.quantity:
				print("Invalid quantity to move.")
				return false

			# Check if we can place the specified quantity at the destination
			if not can_move_item(from_position, to_position, quantity):
				print("Cannot place the specified quantity at the destination.")
				return false

			# Add the quantity to the destination
			if add_item(item, to_position, quantity):
				# Remove the quantity from the source
				remove_item(from_position, quantity)
				return true
			else:
				print("Failed to add the item to the destination.")
				return false
		else:
			# For non-stackable items, quantity is ignored
			# Check if the destination can accommodate the entire item
			if not can_move_item(from_position, to_position):
				print("Cannot place the item at the destination.")
				return false

			# Remove the item from the source
			remove_item(from_position)

			# Add the item to the destination
			if add_item(item, to_position):
				return true
			else:
				# If adding fails, revert by adding the item back to the original position
				add_item(item, from_position)
				print("Failed to add the item to the destination. Reverting.")
				return false
	else:
		print("The source position is covered by another item.")
		return false

# Checks if an item can be moved from one position to another with a specified quantity
# For non-stackable items, quantity is ignored
# Returns true if the move is possible, false otherwise
func can_move_item(from_position: Vector2i, to_position: Vector2i, quantity: int = 1) -> bool:
	if not items.has(from_position):
		return false

	var entry = items[from_position]

	if entry is InventoryEntry:
		var item = entry.item

		if item.is_stackable:
			if quantity < 1 or quantity > entry.quantity:
				return false

			# If destination has the same item, check stack size
			if items.has(to_position):
				var dest_entry = items[to_position]
				if dest_entry is InventoryEntry:
					if dest_entry.item != item:
						return false
					if dest_entry.quantity + quantity > item.max_stack_size:
						return false
					return true
				else:
					# Destination is covered by another item
					return false
			else:
				# Destination is empty; check if the item can be placed there
				return can_place_item(item, to_position, quantity)
		else:
			# Non-stackable items
			# Clone the items dictionary to simulate the move
			var items_copy = items.duplicate(true)

			# Remove the item from the copy
			for y in range(item.dimensions.y):
				for x in range(item.dimensions.x):
					var pos = Vector2i(from_position.x + x, from_position.y + y)
					if items_copy.has(pos):
						items_copy.erase(pos)

			# Temporarily assign the copied items for placement check
			var original_items = items
			items = items_copy

			var can_place = can_place_item(item, to_position)

			# Restore the original items
			items = original_items

			return can_place
	return false


# Optional: Function to swap items between two positions
# Useful if you want to implement drag-and-drop swapping in the GUI
func swap_items(pos_a: Vector2i, pos_b: Vector2i) -> bool:
	if not items.has(pos_a) or not items.has(pos_b):
		return false

	var entry_a = items[pos_a]
	var entry_b = items[pos_b]

	# Check if both positions have main entries
	if not (entry_a is InventoryEntry) or not (entry_b is InventoryEntry):
		return false

	var item_a = entry_a.item
	var quantity_a = entry_a.quantity
	var item_b = entry_b.item
	var quantity_b = entry_b.quantity

	# Check if items can be swapped
	if (item_a.is_stackable and item_b.is_stackable and item_a == item_b):
		# If both are stackable and same type, merge the stacks if possible
		var total_quantity = quantity_a + quantity_b
		if total_quantity <= item_a.max_stack_size:
			# Merge into pos_b
			items[pos_b].quantity = total_quantity
			remove_item(pos_a, quantity_a)
			return true
		else:
			# Fill pos_b to max and update pos_a
			items[pos_b].quantity = item_a.max_stack_size
			items[pos_a].quantity = total_quantity - item_a.max_stack_size
			inventory_updated.emit()
			return true
	else:
		# For non-stackable or different items, attempt to swap
		if can_place_item(item_a, pos_b) and can_place_item(item_b, pos_a):
			# Remove both items
			remove_item(pos_a)
			remove_item(pos_b)

			# Add them to swapped positions
			var added_a = add_item(item_a, pos_b, quantity_a)
			var added_b = add_item(item_b, pos_a, quantity_b)

			if added_a and added_b:
				return true
			else:
				# Revert if adding failed
				add_item(item_a, pos_a, quantity_a)
				add_item(item_b, pos_b, quantity_b)
				return false
		else:
			return false

# Retrieves all main inventory entries (excluding covered cells)
func get_items() -> Array:
	var items_list = []
	for pos in items.keys():
		var entry = items[pos]
		if entry is InventoryEntry:
			items_list.append({"position": pos, "item": entry.item, "quantity": entry.quantity})
	return items_list

# Adds an item to the first available slot, handling stacking and new placements
func add_item_to_first_available_slot(item: Item, quantity: int = 1) -> bool:
	if quantity < 1:
		return false

	if item.is_stackable:
		return _add_stackable_to_first_available_slot(item, quantity)
	else:
		return _add_non_stackable_to_first_available_slot(item)
	
# Internal function to handle adding stackable items to the first available slot
func _add_stackable_to_first_available_slot(item: Item, quantity: int) -> bool:
	# First, try to add to existing stacks
	for entry_data in get_items():
		var existing_item = entry_data.item
		var existing_quantity = entry_data.quantity
		var pos = entry_data.position
		if existing_item == item and existing_quantity < item.max_stack_size:
			var available_space = item.max_stack_size - existing_quantity
			var add_quantity = min(quantity, available_space)
			if add_quantity > 0 and add_item(item, pos, add_quantity):
				quantity -= add_quantity
				if quantity <= 0:
					return true

	# Then, add to new slots
	while quantity > 0:
		var add_quantity = min(quantity, item.max_stack_size)
		var added = false
		for y in range(grid_size.y):
			for x in range(grid_size.x):
				var pos = Vector2i(x, y)
				if can_place_item(item, pos, add_quantity):
					added = add_item(item, pos, add_quantity)
					if added:
						quantity -= add_quantity
						break
			if added:
				break
		if not added:
			return false

	return true

# Internal function to handle adding non-stackable items to the first available slot
func _add_non_stackable_to_first_available_slot(item: Item) -> bool:
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var pos = Vector2i(x, y)
			if can_place_item(item, pos):
				return add_item(item, pos)
	return false

# Splits a stack at the given position
# Returns a dictionary with success status, split quantity, and new position if successful
func split_stack(position: Vector2i) -> Dictionary:
	if not items.has(position):
		return {"success": false, "split_quantity": 0, "item": null}

	var entry = items[position]
	if not (entry is InventoryEntry):
		return {"success": false, "split_quantity": 0, "item": null}

	var item = entry.item
	if not item.is_stackable:
		return {"success": false, "split_quantity": 0, "item": null}

	var current_quantity = entry.quantity
	if current_quantity < 2:
		return {"success": false, "split_quantity": 0, "item": null}  # Cannot split less than 2

	var split_quantity = int(current_quantity / 2)
	var new_quantity = split_quantity

	# Find the first available slot for the split stack
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var pos = Vector2i(x, y)
			if can_place_item(item, pos, new_quantity):
				var added = add_item(item, pos, new_quantity)
				if added:
					entry.quantity -= new_quantity
					inventory_updated.emit()
					return {"success": true, "split_quantity": new_quantity, "new_position": pos}

	# If no slot available, revert the split
	return {"success": false, "split_quantity": 0, "item": null}
	
func _is_in_grid(position: Vector2i) -> bool:
	return (position.x >= 0 and position.x <= grid_size.x and
			position.y >= 0 and position.y <= grid_size.y)
	
func get_item_at(position: Vector2i) -> Item:
	if not _is_in_grid(position):
		return null
	var entry = items.get(position)
	if entry is InventoryEntry:
		return entry.item
	return null
	
# Sorts the inventory based on the given criteria
func sort_inventory(criteria: SortCriteria) -> void:
	var items_to_sort = get_items()

	# Define sorting logic based on criteria
	match criteria:
		SortCriteria.NAME:
			items_to_sort.sort_custom(_sort_by_name)
		SortCriteria.TYPE:
			items_to_sort.sort_custom(_sort_by_type)
		SortCriteria.SIZE:
			items_to_sort.sort_custom(_sort_by_size)
		SortCriteria.QUANTITY:
			items_to_sort.sort_custom(_sort_by_quantity)
		_:
			print("Unknown sorting criteria:", criteria)
			return

	# Clear the inventory
	_clear_inventory()

	# Re-add items in sorted order
	for item_data in items_to_sort:
		var item = item_data.item
		var quantity = item_data.quantity
		add_item_to_first_available_slot(item, quantity)

	inventory_updated.emit()

# Sorting helper functions
func _sort_by_name(a: Dictionary, b: Dictionary) -> int:
	return a.item.name.casecmp_to(b.item.name)

func _sort_by_type(a: Dictionary, b: Dictionary) -> int:
	return a.item.type.compare_to(b.item.type)

func _sort_by_size(a: Dictionary, b: Dictionary) -> int:
	var a_size = a.item.dimensions.x * a.item.dimensions.y
	var b_size = b.item.dimensions.x * b.item.dimensions.y
	if a_size < b_size:
		return -1
	elif a_size > b_size:
		return 1
	else:
		return 0

func _sort_by_quantity(a: Dictionary, b: Dictionary) -> int:
	return b.quantity - a.quantity  # Descending order

# Clears the inventory by removing all items
func _clear_inventory() -> void:
	items.clear()
	inventory_updated.emit()
