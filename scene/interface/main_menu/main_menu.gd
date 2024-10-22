extends Control

@onready var ip_input = %IpInput
@onready var port_input = %PortInput
@onready var connect_bt = %Connect


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_host_pressed():
	MultiplayerManager.host_game()
	GameManager.change_gui_scene("res://scene/interface/hud/hud.tscn", false)


func _on_settings_pressed():
	pass # Replace with function body.


func _on_exit_pressed():
	GameManager.quit_game()


func _on_join_pressed():
	connect_bt.visible = !connect_bt.visible
	ip_input.visible = !ip_input.visible
	port_input.visible = !port_input.visible

func _on_connect_pressed():
	var ip : String = ip_input.text
	var port : int = port_input.text.to_int()
	MultiplayerManager.join_game(ip, port)
	GameManager.change_gui_scene("res://scene/interface/hud/hud.tscn")
