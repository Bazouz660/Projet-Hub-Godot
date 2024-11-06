# ItemPanel.gd
extends Panel
class_name ItemPanel

var item: Item
var grid_position: Vector2i
var quantity: int
var cell_size: int
var cell_margin: int
var split_drag = false

var original_quantity: int = 0  # To store the original quantity

func _ready():
	set_mouse_filter(Control.MOUSE_FILTER_PASS)
	update_quantity_label()

func _get_drag_data(at_position):
	original_quantity = quantity  # Store the original quantity

	var drag_quantity = quantity
	if Input.is_key_pressed(KEY_SHIFT) and quantity > 1:
		drag_quantity = int(quantity) / 2

		split_drag = true
	else:
		split_drag = false

	# Adjust quantity and update label
	quantity -= drag_quantity
	update_quantity_label()

	var drag_offset = _calculate_drag_offset(at_position)
	var drag_data = {
		'item': item,
		'grid_position': grid_position,
		'quantity': drag_quantity,
		'source': self,
		'drag_offset': drag_offset
	}
	# Create a new Control node to hold the preview
	var preview_container = Control.new()
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_container.modulate.a = 0.8

	# Duplicate the item panel
	var item_preview = duplicate()
	item_preview.position = -at_position  # Offset the preview so it aligns with the cursor

	modulate.a = 1.0 if split_drag else 0.3

	# Update the quantity label in the preview to show drag_quantity
	if split_drag:
		var quantity_label = item_preview.get_child(0).get_child(0).get_child(0) as Label
		quantity_label.text = str(drag_quantity)
		
		if original_quantity % 2 != 0:
			drag_quantity += 1
		get_child(0).get_child(0).get_child(0).text = str(drag_quantity)
		
	preview_container.add_child(item_preview)
	set_drag_preview(preview_container)
	return drag_data

func update_quantity_label():
	var quantity_label = get_node_or_null("MarginContainer/TextureRect/QuantityLabel")
	if quantity_label:
		if quantity > 1:
			quantity_label.text = str(quantity)
			quantity_label.show()
		else:
			quantity_label.hide()

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			# Drag was canceled, restore quantity
			quantity = original_quantity
			if split_drag:
				get_child(0).get_child(0).get_child(0).text = str(quantity)
			modulate.a = 1
			update_quantity_label()
		# If drag was successful, the inventory will update the GUI

func _calculate_drag_offset(at_position):
	var cell_size_with_margin = cell_size + cell_margin
	var offset_x = int(at_position.x / cell_size_with_margin)
	var offset_y = int(at_position.y / cell_size_with_margin)
	return Vector2i(offset_x, offset_y)
