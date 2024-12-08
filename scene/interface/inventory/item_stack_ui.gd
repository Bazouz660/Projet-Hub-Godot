extends Control
class_name ItemStackUI

@onready var item_icon: TextureRect = %ItemIcon
@onready var quantity_label: Label = %QuantityLabel

var item_stack: ItemStack:
	set(value):
		item_stack = value
		update_display()

func clear() -> void:
	item_stack = null

func update_display() -> void:
	if not item_stack:
		item_icon.texture = null
		quantity_label.text = ""
		return

	item_icon.texture = item_stack.item.icon

	if item_stack.quantity > 1:
		quantity_label.text = str(item_stack.quantity)
		quantity_label.show()
	else:
		quantity_label.hide()
