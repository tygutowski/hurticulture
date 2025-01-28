extends Item

var energy: int

func begin_being_used() -> void:
	start_digging()

func stop_being_used() -> void:
	stopped_digging()

func finish_being_used() -> void:
	stopped_digging()

func start_digging() -> void:
	Debug.debug("Digging a hole")
	$AnimationPlayer.play("dig")

func stopped_digging():
	$AnimationPlayer.play("stop")
