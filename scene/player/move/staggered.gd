extends Move

func on_enter_state():
	humanoid.velocity.x = 0
	humanoid.velocity.z = 0