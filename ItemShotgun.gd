extends Gun

var pellet_count: int = 10

@onready var barrel_pivot = get_node("BarrelPivot")

func fire_projectile() -> void:
	Debug.debug("BLAM")
