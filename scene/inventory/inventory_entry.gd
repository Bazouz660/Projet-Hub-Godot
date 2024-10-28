# InventoryEntry.gd
extends RefCounted

class_name InventoryEntry

# The item contained in this inventory entry
var item: Item

# The quantity of the item
var quantity: int

# Constructor to initialize the inventory entry
func _init(p_item: Item, p_quantity: int):
	item = p_item
	quantity = p_quantity
