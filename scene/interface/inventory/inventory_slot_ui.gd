extends Control
class_name InventorySlotUI

@onready var item_icon: TextureRect = $ItemIcon
@onready var item_quantity: Label = $QuantityLabel

var slot_index: int = 0

signal slot_clicked(index: int)
signal slot_right_clicked(index: int)

func _ready() -> void:
	item_icon.visible = false
	item_quantity.visible = false
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_clicked.emit(slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			slot_right_clicked.emit(slot_index)

func update_display(item: Item, quantity: int) -> void:
	if item and quantity > 0:
		item_icon.texture = item.icon
		item_icon.visible = true

		if item.is_stackable and quantity > 1:
			item_quantity.text = str(quantity)
			item_quantity.visible = true
		else:
			item_quantity.visible = false
	else:
		item_icon.visible = false
		item_quantity.visible = false
