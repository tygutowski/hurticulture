extends Node3D

func _on_area_3d_body_entered(body) -> void:
	if body is Fruit:
		var fuel_amount = body.fuel_amount
		PowerManager.current_power += fuel_amount
		body.get_dropped()
		body.queue_free()
		
