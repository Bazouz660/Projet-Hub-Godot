extends MarginContainer

@onready var ip_input = %IpInput
@onready var port_input = %PortInput
@onready var connect_bt = %Connect

func _on_host_pressed():
	MultiplayerManager.host_game()
	SceneManager.change_gui_scene("res://scene/interface/hud/hud.tscn")


func _on_settings_pressed():
	MenuManager.go_to_menu("Settings")


func _on_exit_pressed():
	SceneManager.quit_game()


func _on_join_pressed():
	connect_bt.visible = !connect_bt.visible
	ip_input.visible = !ip_input.visible
	port_input.visible = !port_input.visible


func _on_connect_pressed():
	var ip : String = ip_input.text
	var port : int = port_input.text.to_int()
	MultiplayerManager.join_game(ip, port)
	SceneManager.change_gui_scene("res://scene/interface/hud/hud.tscn")
