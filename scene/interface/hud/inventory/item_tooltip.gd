extends Control

var item: InventoryItem:
	set(value):
		if value != item:
			_old_item = item
			item = value
			_on_item_changed()

var _old_item: InventoryItem = null

@onready var item_title: Label = %ItemTitle
@onready var item_description: Label = %ItemDescription
@onready var item_icon: TextureRect = %ItemIcon
@onready var item_properties: Label = %ItemProperties

# Called when the node enters the scene tree for the first time.
func _ready():
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if !is_visible():
		return

	# Resize the container to fit the content

func _on_item_changed() -> void:
	if item == null:
		return

	item_title.text = item.get_title()
	item_description.text = item.get_property("description", "No description")
	item_icon.texture = item.get_texture()

	var properties_text: String = ""
	for property in item.get_properties():
		properties_text += property + ": " + str(item.get_property(property)) + "\n"
	item_properties.text = properties_text.strip_edges()

	# Resize the container to fit the content
	var minimum_size: Vector2 = Vector2(0, 0)
	for child in get_children():
		if child is Control:
			minimum_size = minimum_size.max(child.get_combined_minimum_size())
	size = minimum_size

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position() + Vector2(10, 10)
