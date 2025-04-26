extends Control
class_name HumanoidInventoryHUD

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

func init():
	ctrl_inventory_grid.inventory = inventory
	grid_constraint = inventory.get_constraint(GridConstraint)
	if grid_constraint == null:
		push_error("GridConstraint not found in inventory")
		return

	# Initialize the CtrlItemSlots
	ctrl_head_slot.init(head_slot)
	ctrl_body_slot.init(chest_slot)
	ctrl_back_slot.init(shirt_slot)
	ctrl_legs_slot.init(legs_slot)
	ctrl_feet_slot.init(feet_slot)
	ctrl_hands_slot.init(hands_slot)
	ctrl_weapon_slot.init(weapon_slot)

	# Connect signals
	_connect_signals()


func _connect_signals():
	# Listen for when an item is right-clicked
	ctrl_inventory_grid.inventory_item_clicked.connect(_on_item_clicked)
	ctrl_inventory_grid.item_mouse_entered.connect(_show_tooltip)
	ctrl_inventory_grid.item_mouse_exited.connect(_hide_tooltip)
	# Connect the button's pressed signal to the _on_pressed function
	sort_button.pressed.connect(_on_pressed)


func _show_tooltip(item: InventoryItem):
	tooltip.item = item
	tooltip.show()
	TweenAnimator.fade_in(tooltip, 0.1)

	if hide_tooltip_timer != null:
		hide_tooltip_timer.stop()
		hide_tooltip_timer.queue_free()


func _hide_tooltip(item: InventoryItem):
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
	add_child.call_deferred(hide_tooltip_timer)
	hide_tooltip_timer.start.call_deferred()


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

func _can_drop_data(_at_position, data):
	return data is InventoryItem

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	print("Dropped item: ", data)
	inventory.remove_item(data)
	var player_position = MultiplayerManager.active_player.global_position
	var item_data := Seriously.pack_to_bytes(data.serialize())
	if item_data == null:
		push_error("Failed to serialize item data")
		return
	# send the item data to all peers
	_rpc_drop_item.rpc(item_data, player_position, Time.get_ticks_msec())


@rpc("any_peer", "call_local", "reliable")
func _rpc_drop_item(item_data: PackedByteArray, item_position: Vector3, time_dropped: int) -> void:
	# unpack the item data
	var unpacked_item_dict := Seriously.unpack_from_bytes(item_data) as Dictionary
	if unpacked_item_dict == null:
		push_error("Failed to unpack item data")
		return
	
	# create a new InventoryItem instance
	var item := InventoryItem.new()
	item.deserialize(unpacked_item_dict)
	if item == null:
		push_error("Failed to deserialize item data")
		return

	DroppedItem.create(item, item_position, time_dropped)