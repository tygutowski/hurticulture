extends Node3D

var already_interacted: bool = false

func interact() -> void:
	if already_interacted:
		return
	PowerManager.start_game()
	already_interacted = true
