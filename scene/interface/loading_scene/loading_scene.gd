extends Control
class_name LoadingScene

var scene_name
var scene_load_status = 0
@onready var percentage = %Percentage as Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func reset():
	percentage.text = "0%"

func update_progress(progress):
	percentage.text = str(floor(progress * 100)) + "%"
