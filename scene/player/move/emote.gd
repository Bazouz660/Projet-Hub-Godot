extends Move
class_name Emote

func on_enter_state():
	humanoid.velocity.x = 0
	humanoid.velocity.z = 0
