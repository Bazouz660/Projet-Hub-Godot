extends Node
class_name Root

@onready var world = $World
@onready var gui = $GUI

func _ready():
	GameManager.root = self
	GameManager._current_gui_scene = $GUI/MainMenu
	MultiplayerManager.root = self
