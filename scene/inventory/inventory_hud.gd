extends Control
class_name InventoryHud

@onready var grid = %Grid

@export var inventory: Inventory :
	get:
		return inventory
	set(value):
		inventory = value
		grid.inventory = inventory

func _ready():
	MultiplayerManager.active_player_loaded.connect(_set_inventory)
	
func _set_inventory():
	print("Active player name: ", MultiplayerManager.active_player.name)
	await MultiplayerManager.active_player.ready
	print( MultiplayerManager.active_player.inventory)
	inventory = MultiplayerManager.active_player.inventory
