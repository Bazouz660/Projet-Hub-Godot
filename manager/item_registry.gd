extends Node

const ITEMS_DATA_PATH = "res://data/item/"
var items: Dictionary = {}

func _ready():
	if !DirAccess.dir_exists_absolute(ITEMS_DATA_PATH):
		printerr("Item data directory does not exist.")
		return

	var dir = DirAccess.open(ITEMS_DATA_PATH)
	for file in dir.get_files():
		if file.get_extension() == "res":
			var item = load(ITEMS_DATA_PATH + file)
			if item is Item:
				items[item.id] = item
				print("Loaded item: " + item.name)
			else:
				printerr("Failed to load item from file: " + file)

func get_item_by_id(item_id: String) -> Item:
	if items.has(item_id):
		return items[item_id]
	printerr("Item with id " + item_id + " not found.")
	return null
