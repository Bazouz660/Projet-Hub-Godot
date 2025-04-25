extends Control

@export var inventory: Inventory
@export var head_slot: ItemSlot
@export var chest_slot: ItemSlot
@export var shirt_slot: ItemSlot
@export var legs_slot: ItemSlot
@export var feet_slot: ItemSlot
@export var hands_slot: ItemSlot
@export var weapon_slot: ItemSlot
@export var tooltip: Control

@onready var sort_button: Button = %SortButton
@onready var ctrl_inventory_grid: CtrlInventoryGrid = %CtrlInventoryGrid
@onready var ctrl_head_slot := %CtrlHeadSlot
@onready var ctrl_body_slot := %CtrlChestSlot
@onready var ctrl_back_slot := %CtrlShirtSlot
@onready var ctrl_legs_slot := %CtrlLegsSlot
@onready var ctrl_feet_slot := %CtrlFeetSlot
@onready var ctrl_hands_slot := %CtrlHandsSlot

@onready var ctrl_weapon_slot := %CtrlWeaponSlot

var grid_constraint: GridConstraint = null

var hide_tooltip_timer: Timer = null

func _ready():
	# Set the inventory for the CtrlInventory
	ctrl_inventory_grid.inventory = inventory
	grid_constraint = inventory.get_constraint(GridConstraint)
	if grid_constraint == null:
		push_error("GridConstraint not found in inventory")
		return

	# Listen for when an item is right-clicked
	ctrl_inventory_grid.inventory_item_clicked.connect(_on_item_clicked)

	ctrl_inventory_grid.item_mouse_entered.connect(func(item: InventoryItem):
		tooltip.item = item
		tooltip.show()
		TweenAnimator.fade_in(tooltip, 0.1)

		if hide_tooltip_timer != null:
			hide_tooltip_timer.stop()
			hide_tooltip_timer.queue_free()
	)

	ctrl_inventory_grid.item_mouse_exited.connect(func(item: InventoryItem):
		tooltip.item = null

		if hide_tooltip_timer != null:
			hide_tooltip_timer.start()
			return

		hide_tooltip_timer = Timer.new()
		hide_tooltip_timer.wait_time = 0.1
		hide_tooltip_timer.one_shot = true
		hide_tooltip_timer.timeout.connect(func():
			TweenAnimator.fade_out(tooltip, 0.1)
			hide_tooltip_timer.queue_free()
		)
		add_child(hide_tooltip_timer)
		hide_tooltip_timer.start()
	)


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
	if grid_constraint == null:
		return
	grid_constraint.sort()

func _on_item_clicked(item: InventoryItem, _position: Vector2, button: int):
	# rotate the item
	if item == null:
		return
	if button != MOUSE_BUTTON_RIGHT:
		return
	grid_constraint.rotate_item(item)
	# Update the CtrlInventoryGrid to reflect the changes
