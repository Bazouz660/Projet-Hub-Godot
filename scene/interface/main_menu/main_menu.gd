extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MenuStateManager.set_game_state(MenuStateManager.GameState.MAIN_MENU)
	MenuManager.go_to_menu.call_deferred("Main")
