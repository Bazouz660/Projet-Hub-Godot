extends CenterContainer
class_name SlotUI

@onready var item_stack_ui: ItemStackUI = $ItemStackUI

var _slot_empty_texture: Texture = preload("res://asset/texture/interface/inventory/slot_empty.png")
var _slot_active_texture: Texture = preload("res://asset/texture/interface/inventory/slot_active.png")

var item_stack: ItemStack:
    set(item_stack):
        item_stack_ui.item_stack = item_stack
        update_display()
    get():
        return item_stack_ui.item_stack

signal slot_clicked(slot: SlotUI)
signal slot_right_clicked(slot: SlotUI)
signal slot_hovered(slot: SlotUI)

func update_display() -> void:
    item_stack_ui.update_display()
    if item_stack:
        $TextureRect.texture = _slot_active_texture
    else:
        $TextureRect.texture = _slot_empty_texture

func clear() -> void:
    item_stack_ui.clear()
    update_display()

func select_item_stack() -> ItemStack:
    var selected_stack = item_stack_ui.item_stack
    item_stack_ui.clear()
    return selected_stack

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            slot_clicked.emit(self)
        elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            slot_right_clicked.emit(self)
    if event is InputEventMouseMotion:
        slot_hovered.emit(self)