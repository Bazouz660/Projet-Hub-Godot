extends Control
class_name InventoryHud

@onready var grid = %Grid
@export var enable : bool = true

@export var inventory: Inventory :
	get:
		return inventory
	set(value):
		inventory = value
		grid.inventory = inventory

func _ready():
	MultiplayerManager.active_player_loaded.connect(_set_inventory)
	
func _set_inventory(_id):
	if !enable:
		return
	
	print("Active player name: ", MultiplayerManager.active_player.name)
	print( MultiplayerManager.active_player.inventory)
	inventory = MultiplayerManager.active_player.inventory
