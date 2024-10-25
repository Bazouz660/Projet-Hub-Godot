extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	MenuStateManager.set_game_state(MenuStateManager.GameState.IN_GAME)
