extends SubViewport

func _input(event) -> void:
	if event is InputEventMouseMotion:
		print(event.position)
