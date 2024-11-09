extends Control
class_name MenuManager

@export var toggle_menus : Array[ToggleMenu]
@export var default_menu : Control
@export var toggle_mouse : bool = false
@export var disable_player_input : bool = false

var menus_map : Dictionary
var current_menu : Control = null
var current_menu_name = ""
var navigation_history : Array

func _ready():
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	find_menus()
	SceneManager.disable_player_input = false
	
	if is_instance_valid(default_menu):
		go_to_menu(default_menu.name)

func find_menus():
	for child in get_children():
		if child is Control:
			menus_map.get_or_add(child.name, child) 
		
func clear_history():
	navigation_history.clear()
	current_menu = null
	current_menu_name = ""

func go_to_menu(menu_name: String, save_in_history : bool = true):
	if is_instance_valid(current_menu):
		if save_in_history:
			navigation_history.append(current_menu_name)
		current_menu.hide()
		SceneManager.disable_player_input = false
		current_menu_name = ""
	if menu_name == "":
		if toggle_mouse:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	current_menu = menus_map[menu_name]
	current_menu.show()
	if disable_player_input:
		SceneManager.disable_player_input = true
	current_menu_name = menu_name
	_set_focus_on_first_button.call_deferred(current_menu)
	
func _set_focus_on_first_button(parent : Control) -> bool:
	if is_instance_valid(current_menu) and current_menu.has_meta("first_focus"):
		(current_menu.get_meta("first_focus") as Control).grab_focus()
		return true
	
	for child in parent.get_children():
		if child is BaseButton:
			child.grab_focus()
			return true
	# If no button is found in the child, try again on the children childs
	for child in parent.get_children():
		if child is Control:
			if _set_focus_on_first_button(child):
				return true
	return false
	
func go_to_last_menu() -> bool:
	if !navigation_history.is_empty():
		go_to_menu(navigation_history.pop_back(), false)
		return true
	return false
	
func get_history() -> Array:
	return navigation_history
	
func close_menu():
	go_to_menu("", false)
	clear_history()
	
func _toggle_menu(menu_name : String) -> void:
	if !go_to_last_menu():
		if current_menu_name != menu_name:
			go_to_menu(menu_name)
			if toggle_mouse:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif current_menu_name == menu_name:
			close_menu()


func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_cancel") and !navigation_history.is_empty():
		go_to_last_menu()
		return
	
	for menu in toggle_menus:
		if Input.is_action_just_pressed(menu.action):
			_toggle_menu(menu.menu_name)
