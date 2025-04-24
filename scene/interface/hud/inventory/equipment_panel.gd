extends Panel
class_name EquipmentPanel

@export var icon_texture: Texture2D
@export var item_slot: ItemSlot = null

@onready var texture_rect: TextureRect = $TextureRect
@onready var ctrl_item_slot: CtrlItemSlot = $TextureRect/CtrlItemSlot

# Called when the node enters the scene tree for the first time.
func _ready():
	texture_rect.texture = icon_texture
	if item_slot != null:
		init(item_slot)


func init(p_item_slot: ItemSlot):
	ctrl_item_slot.item_slot = p_item_slot
	ctrl_item_slot.item_slot.item_equipped.connect(_on_item_equipped)
	ctrl_item_slot.item_slot.cleared.connect(_on_item_unequipped)

func _on_item_equipped():
	texture_rect.self_modulate = Color.TRANSPARENT

func _on_item_unequipped():
	texture_rect.self_modulate = Color(1, 1, 1, 0.5)
