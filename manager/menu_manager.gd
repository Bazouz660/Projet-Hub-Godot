extends Node

var menus : Array[Menu]

var menus_map : Dictionary
var current_menu : Control = null
var current_menu_name = ""
var navigation_history : Array

func _ready():
	
	_create_menu("Main", "res://scene/interface/main_menu/main_menu_content.tscn")
	_create_menu("Settings", "res://scene/interface/settings_menu/settings_menu.tscn")
	_create_menu("Pause", "res://scene/interface/pause_menu/pause_menu.tscn")

	_load_menus()
	
func _create_menu(menu_name, path):
	var menu : Menu = Menu.new()
	menu.name = menu_name
	menu.path = path
	menus.append(menu)

func _load_menus():
	for menu in menus:
		var packed_menu = load(menu.path)
		menu.packed_scene = packed_menu
		menus_map.get_or_add(menu.name, menu)
		
func clear_history():
	navigation_history.clear()
	current_menu = null
	current_menu_name = ""

func go_to_menu(menu_name: String, save_in_history : bool = true):
	if is_instance_valid(current_menu):
		if save_in_history:
			navigation_history.append(current_menu_name)
		current_menu.queue_free()
		current_menu_name = ""
	if menu_name == "":
		return
	current_menu = menus_map[menu_name].packed_scene.instantiate()
	current_menu_name = menu_name
	SceneManager.current_gui_scene.add_child.call_deferred(current_menu)
	_set_focus_on_first_button.call_deferred(current_menu)
	
func _set_focus_on_first_button(parent : Control) -> bool:
	for child in parent.get_children():
		if child is BaseButton:
			child.grab_focus()
			return true
	# If no button is found in the child, try again on the children childs
	for child in parent.get_children():
		if _set_focus_on_first_button(child):
			return true
	return false
	
func go_to_last_menu() -> bool:
	print(navigation_history)
	if !navigation_history.is_empty():
		go_to_menu(navigation_history.pop_back(), false)
		return true
	return false
	
func get_history() -> Array:
	return navigation_history
	
func close_menu():
	go_to_menu("", false)

func _input(event):
	if Input.is_action_just_pressed("pause"):
		if !go_to_last_menu():
			if MenuStateManager.can_open_menu("Pause") and current_menu_name != "Pause":
				go_to_menu("Pause")
			elif current_menu_name == "Pause":
				close_menu()
