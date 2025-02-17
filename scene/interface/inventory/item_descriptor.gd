extends Control
class_name ItemDescriptor

@onready var _background: TextureRect = $Background
@onready var _item_icon: TextureRect = $ItemIcon
@onready var _item_name: Label = $ItemName
@onready var _item_description: Label = $ItemDescription

var _item_descriptor_active_texture: Texture = preload("res://asset/texture/interface/inventory/item_descriptor_active.png")
var _item_descriptor_texture: Texture = preload("res://asset/texture/interface/inventory/item_descriptor.png")

func show_item(slot: SlotUI) -> void:
    if slot.item_stack:
        var item = ItemRegistry.get_item_by_id(slot.item_stack.item_id)
        _background.texture = _item_descriptor_active_texture
        _item_icon.texture = item.icon
        _item_name.text = item.name
        _item_description.text = item.description
    else:
        clear()

func clear() -> void:
    _background.texture = _item_descriptor_texture
    _item_icon.texture = null
    _item_name.text = ""
    _item_description.text = ""