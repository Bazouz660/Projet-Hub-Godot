extends Node3D

func _physics_process(_delta):
	if !self.is_node_ready():
		return
	var player = MultiplayerManager.active_player
	if player:
		global_position.x = player.global_position.x
		global_position.z = player.global_position.z
