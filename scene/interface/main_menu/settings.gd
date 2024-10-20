extends Button

@onready var sound_pool = $SoundPool

func _on_pressed():
	sound_pool.play_random_sound()
