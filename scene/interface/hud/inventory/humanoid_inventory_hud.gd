extends Control

@export var inventory: Inventory
@export var head_slot: ItemSlot
@export var chest_slot: ItemSlot
@export var shirt_slot: ItemSlot
@export var legs_slot: ItemSlot
@export var feet_slot: ItemSlot
@export var hands_slot: ItemSlot
@export var weapon_slot: ItemSlot

@onready var sort_button: Button = %SortButton
@onready var ctrl_inventory: CtrlInventoryGrid = %CtrlInventoryGrid
@onready var ctrl_head_slot := %CtrlHeadSlot
@onready var ctrl_body_slot := %CtrlChestSlot
@onready var ctrl_back_slot := %CtrlShirtSlot
@onready var ctrl_legs_slot := %CtrlLegsSlot
@onready var ctrl_feet_slot := %CtrlFeetSlot
@onready var ctrl_hands_slot := %CtrlHandsSlot

@onready var ctrl_weapon_slot := %CtrlWeaponSlot

func _ready():
	# Set the inventory for the CtrlInventory
	ctrl_inventory.inventory = inventory


	# Initialize the CtrlItemSlots
	ctrl_head_slot.init(head_slot)
	ctrl_body_slot.init(chest_slot)
	ctrl_back_slot.init(shirt_slot)
	ctrl_legs_slot.init(legs_slot)
	ctrl_feet_slot.init(feet_slot)
	ctrl_hands_slot.init(hands_slot)
	ctrl_weapon_slot.init(weapon_slot)

	# Connect the button's pressed signal to the _on_pressed function
	sort_button.pressed.connect(_on_pressed)

func _on_pressed():
	var grid_constraint: GridConstraint = inventory.get_constraint(GridConstraint)
	if grid_constraint == null:
		return
	grid_constraint.sort()
