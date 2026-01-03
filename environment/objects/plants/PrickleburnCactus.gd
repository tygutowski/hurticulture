extends Plant

func _ready() -> void:
	super._ready()
	get_node("StaticBody3D/Body").shape = get_node("StaticBody3D/Body").shape.duplicate()
	get_node("StaticBody3D/Arm1").shape = get_node("StaticBody3D/Arm1").shape.duplicate()
	get_node("StaticBody3D/Arm2").shape = get_node("StaticBody3D/Arm2").shape.duplicate()
