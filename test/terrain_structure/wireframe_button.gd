extends Button

var enabled = false

func _on_pressed():
	enabled = !enabled
	if !enabled:
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
	else:
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
