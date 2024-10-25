extends Node

# Enum for different game states
enum GameState {
	MAIN_MENU,
	IN_GAME,
	LOADING,
	CUTSCENE,
	DIALOGUE,
	GAME_OVER
}

# Menu access configuration
class MenuAccess:
	var allowed_states: Array[GameState]
	var blocked_by_menus: Array[String]
	
	func _init(states: Array[GameState], blocking_menus: Array[String] = []):
		allowed_states = states
		blocked_by_menus = blocking_menus

# Current game state
var current_state: GameState = GameState.MAIN_MENU

# Menu access configurations
var menu_access: Dictionary = {}


func _ready():
	# Configure which menus can be opened in which states
	setup_menu_access()
	
func setup_menu_access():
	# Configure Pause Menu
	menu_access["Pause"] = MenuAccess.new([
		GameState.IN_GAME
	], ["Settings"])  # Can't open pause menu when settings is open
	
	# Configure Settings Menu
	menu_access["Settings"] = MenuAccess.new([
		GameState.MAIN_MENU,
		GameState.IN_GAME
	])
	
	# Configure Main Menu
	menu_access["Main"] = MenuAccess.new([
		GameState.MAIN_MENU
	])
	
	# Configure Inventory (example)
	menu_access["Inventory"] = MenuAccess.new([
		GameState.IN_GAME
	], ["Pause", "Settings"])  # Can't open inventory when pause or settings are open

func can_open_menu(menu_name: String) -> bool:
	# Check if menu exists
	if !menu_access.has(menu_name):
		push_warning("Attempted to check access for non-existent menu: " + menu_name)
		return false
	
	# Get menu access configuration
	var access: MenuAccess = menu_access[menu_name]
	
	# Check if current state allows this menu
	if !access.allowed_states.has(current_state):
		return false
	
	# Check if any blocking menus are currently open
	var current_menu = MenuManager.current_menu_name
	if current_menu in access.blocked_by_menus:
		return false
	
	return true

func set_game_state(new_state: GameState):
	current_state = new_state
	# Optionally close menus that shouldn't be open in the new state
	check_and_close_invalid_menus()

func check_and_close_invalid_menus():
	if MenuManager.current_menu_name != "":
		if !can_open_menu(MenuManager.current_menu_name):
			MenuManager.close_menu()

# Modified input handling for MenuManager
func handle_menu_input(menu_name: String) -> bool:
	if can_open_menu(menu_name):
		MenuManager.go_to_menu(menu_name)
		return true
	return false
