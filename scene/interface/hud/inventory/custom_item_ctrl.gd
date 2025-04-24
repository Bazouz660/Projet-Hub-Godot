@tool
extends CtrlInventoryItemBase
class_name CtrlItemCustom

@onready var texture_rect: TextureRect = %TextureRect

func _ready():
	item_changed.connect(_on_item_changed)
	icon_stretch_mode_changed.connect(_on_icon_stretch_mode_changed)

	icon_stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED

	if item != null:
		texture_rect.texture = item.get_texture()
		texture_rect.stretch_mode = icon_stretch_mode

func _on_item_changed():
	if item.get_texture() == null:
		return
	texture_rect.texture = item.get_texture()

func _on_icon_stretch_mode_changed():
	texture_rect.stretch_mode = icon_stretch_mode