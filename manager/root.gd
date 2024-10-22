extends Node
class_name Root

@onready var world = $World
@onready var gui = $GUI
@onready var loading_scene = $LoadingScene as LoadingScene

func _ready():
	GameManager.root = self
	GameManager.current_gui_scene = $GUI/MainMenu
	MultiplayerManager.root = self
