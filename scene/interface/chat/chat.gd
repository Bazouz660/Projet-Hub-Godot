extends Control

@onready var messages = $MarginContainer/VBoxContainer/Messages as TextEdit
@onready var message = $MarginContainer/VBoxContainer/HBoxContainer/Message as LineEdit
@onready var send = $MarginContainer/VBoxContainer/HBoxContainer/Send

var msg : String
var username : String = "Test"

func _ready():
	MultiplayerManager.active_player_loaded.connect(func(id): username = str(id))

@rpc("any_peer", "call_local", "reliable")
func _msg_rpc(usrnm : String, message : String):
	messages.text += usrnm + ": " + message + "\n"

func _on_send_pressed():
	if message.text == "":
		return

	_msg_rpc.rpc(username, message.text)
	message.text = ""
	
	messages.scroll_vertical = messages.get_line_count()
