extends Move

func on_enter_state():
	humanoid.velocity.x = 0
	humanoid.velocity.z = 0
	DURATION = moves_data_repo.get_duration(backend_animation) * 2

func on_exit_state():
	resources.gain_health(9999999)