extends Item

func begin_being_used() -> void:
	start_digging()

func stop_being_used() -> void:
	stopped_digging()

func finish_being_used() -> void:
	stopped_digging()

func start_digging() -> void:
	Debug.debug("Began digging a hole")
	$AnimationPlayer.play("dig")

func stopped_digging():
	Debug.debug("Stopped digging a hole")
	$AnimationPlayer.play("stop")
