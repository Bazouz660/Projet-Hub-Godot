# InventoryHUD.gd
extends GridContainer

@export var inventory: Inventory :
	get:
		return inventory
	set(value):
		if !is_instance_valid(value):
			return
		inventory = value
		inventory.inventory_updated.connect(update_gui)
		columns = inventory.grid_size.x
		_create_grid()
		update_gui()


@export var cell_size: int = 64
@export var cell_margin: int = 4

var cell_containers: Array[Control] = []

# Variables to track dragging state
var is_dragging = false
var current_drag_data = null
var current_drop_position = Vector2i(-1, -1)


func _ready():
	set_anchors_preset(Control.PRESET_CENTER)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	set_process(true)
	
	# Set up the grid layout
	add_theme_constant_override("h_separation", cell_margin)
	add_theme_constant_override("v_separation", cell_margin)

func _create_grid():
	for y in range(inventory.grid_size.y):
		for x in range(inventory.grid_size.x):
			var cell_container = Panel.new()
			cell_container.custom_minimum_size = Vector2(cell_size, cell_size)
			cell_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var style_box = cell_container.get_theme_stylebox("panel") as StyleBoxFlat
			style_box.bg_color.a = 0.1
			style_box.border_color = style_box.bg_color
			style_box.border_width_bottom = 2
			style_box.border_width_left = 0
			style_box.border_width_right = 2
			style_box.border_width_top = 0
			cell_container.add_theme_stylebox_override("panel", style_box)
			add_child(cell_container)
			cell_containers.append(cell_container)

func update_gui():
	# Clear existing items
	for cell in cell_containers:
		for child in cell.get_children():
			child.queue_free()
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.43, 0.38, 0.30, 1)
	style_box.set_corner_radius_all(5)
	style_box.border_color = style_box.bg_color.darkened(0.25)
	style_box.border_width_bottom = 3
	style_box.border_width_right = 3
	# Add items to the grid
	for item_data in inventory.get_items():
		var item = item_data.item
		var grid_position = item_data.position  # Use grid_position instead of position
		var quantity = item_data.quantity
		
		var item_panel = ItemPanel.new()
		item_panel.z_index = 1
		var item_size = Vector2(
			item.dimensions.x * cell_size + (item.dimensions.x - 1) * cell_margin,
			item.dimensions.y * cell_size + (item.dimensions.y - 1) * cell_margin
		)
		item_panel.cell_size = cell_size
		item_panel.cell_margin = cell_margin
		item_panel.custom_minimum_size = item_size
		item_panel.size = item_size
		item_panel.item = item
		item_panel.grid_position = grid_position  # Set grid_position
		item_panel.quantity = quantity

		item_panel.add_theme_stylebox_override("panel", style_box)
		
		var item_margin = MarginContainer.new()
		item_margin.name = "ItemMargin"
		item_margin.add_theme_constant_override("margin_left", cell_margin)
		item_margin.add_theme_constant_override("margin_top", cell_margin)
		item_margin.add_theme_constant_override("margin_right", cell_margin)
		item_margin.add_theme_constant_override("margin_bottom", cell_margin)
		item_margin.set_anchors_preset(Control.PRESET_FULL_RECT)

		var item_texture = TextureRect.new()
		item_texture.texture = item.texture
		item_texture.name = "ItemTexture"
		item_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_texture.set_anchors_preset(Control.PRESET_FULL_RECT)

		item_margin.add_child(item_texture)
		item_panel.add_child(item_margin)
		
		var cell_index = grid_position.y * inventory.grid_size.x + grid_position.x
		if cell_index < cell_containers.size():
			cell_containers[cell_index].add_child(item_panel)
		
		if quantity > 1:
			var quantity_label = Label.new()
			quantity_label.name = "QuantityLabel"  # Set name for easy access
			quantity_label.z_index = 1
			quantity_label.text = str(quantity)
			quantity_label.add_theme_color_override("font_color", Color.WHITE)
			quantity_label.add_theme_color_override("font_outline_color", Color.BLACK)
			quantity_label.add_theme_constant_override("outline_size", 1)
			quantity_label.position = Vector2(
				item_size.x - 20 + cell_margin, 
				item_size.y - 20 - cell_margin
			)
			item_texture.add_child(quantity_label)


func _get_grid_position(local_position: Vector2) -> Vector2i:
	# No need to subtract global_position; local_position is already in local coordinates
	var x = int(local_position.x / (cell_size + cell_margin))
	var y = int(local_position.y / (cell_size + cell_margin))
	
	if x >= 0 and x < inventory.grid_size.x and y >= 0 and y < inventory.grid_size.y:
		return Vector2i(x, y)
	return Vector2i(-1, -1)

func _can_drop_data(at_position, data):
	if data.has('item') and data.has('grid_position'):
		var quantity = data['quantity'] as int
		var drag_offset = data['drag_offset'] as Vector2i
		var drop_pos = _get_grid_position(at_position)
		var adjusted_drop_pos = drop_pos - drag_offset
		# Update the current drop position
		current_drop_position = adjusted_drop_pos
		current_drag_data = data
		is_dragging = true
		# Check if the item can be placed at adjusted_drop_pos
		var can_place = inventory.can_move_item(data['grid_position'], adjusted_drop_pos, quantity)
		queue_redraw()  # Redraw the preview
		return can_place
	return false


func _drop_data(at_position, data):
	if data.has('item') and data.has('grid_position'):
		var drag_quantity = data['quantity'] as int
		var original_position = data['grid_position'] as Vector2i
		var drag_offset = data['drag_offset'] as Vector2i
		var drop_pos = _get_grid_position(at_position)
		var adjusted_drop_pos = drop_pos - drag_offset

		# Adjust inventory quantities
		inventory.move_item(original_position, adjusted_drop_pos, drag_quantity)

		# Reset dragging state
		is_dragging = false
		current_drag_data = null
		current_drop_position = Vector2i(-1, -1)
		update_gui()
		queue_redraw()

func _process(_delta):
	if is_dragging and current_drag_data != null:
		var mouse_pos = get_local_mouse_position()
		var drop_pos = _get_grid_position(mouse_pos)
		var drag_offset = current_drag_data['drag_offset'] as Vector2i
		var adjusted_drop_pos = drop_pos - drag_offset
		if adjusted_drop_pos != current_drop_position:
			current_drop_position = adjusted_drop_pos
			queue_redraw()  # Redraw the preview
			
func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		is_dragging = false
		current_drag_data = null
		current_drop_position = Vector2i(-1, -1)
		queue_redraw()

func _draw():
	if is_dragging and current_drag_data != null and current_drop_position != Vector2i(-1, -1):
		var item = current_drag_data['item'] as Item
		var dimensions = item.dimensions
		var color = Color(0, 1, 0, 0.5)  # Green for valid placement
		var can_place = inventory.can_move_item(
			current_drag_data['grid_position'],
			current_drop_position,
			current_drag_data['quantity']
		)
		if not can_place:
			color = Color(1, 0, 0, 0.5)  # Red for invalid placement

		var cell_size_with_margin = cell_size + cell_margin

		# Calculate grid boundaries
		var grid_width = inventory.grid_size.x * cell_size_with_margin - cell_margin
		var grid_height = inventory.grid_size.y * cell_size_with_margin - cell_margin

		# Original rectangle
		var rect_position = Vector2(
			current_drop_position.x * cell_size_with_margin,
			current_drop_position.y * cell_size_with_margin
		)
		var rect_size = Vector2(
			dimensions.x * cell_size_with_margin - cell_margin,
			dimensions.y * cell_size_with_margin - cell_margin
		)

		# Adjust rectangle to clip within grid boundaries
		var rect_end = rect_position + rect_size

		rect_position.x = clamp(rect_position.x, 0, grid_width)
		rect_position.y = clamp(rect_position.y, 0, grid_height)

		rect_end.x = clamp(rect_end.x, 0, grid_width)
		rect_end.y = clamp(rect_end.y, 0, grid_height)

		rect_size = rect_end - rect_position

		# Only draw if the rectangle has positive size
		if rect_size.x > 0 and rect_size.y > 0:
			draw_rect(Rect2(rect_position, rect_size), color)


func _on_sort_button_pressed():
	if is_instance_valid(inventory):
		inventory.sort_inventory(inventory.SortCriteria.NAME)
