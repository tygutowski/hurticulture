extends Gun


func fire_projectile() -> void:
	if thing_holding_me.is_in_group("player"):
		var ray: RayCast3D = thing_holding_me.head_pivot.get_node("ShootRay")
		ray.force_raycast_update()
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider is StaticBody3D:
				var point = ray.get_collision_point()
				var normal = ray.get_collision_normal()
				var decal: Node3D = decal_scene.instantiate()
				get_tree().get_first_node_in_group("world").add_child(decal)
				decal.global_position = point

				var new_y = -normal
				var new_x = new_y.cross(Vector3.UP).normalized()
				
				# if new_x is too small (parallel vectors), use another axis
				if is_zero_approx(new_x.length()):
					new_x = new_y.cross(Vector3.FORWARD).normalized()
				var new_z = new_x.cross(new_y).normalized()
				
				var b = Basis(new_x, new_y, new_z)
				decal.global_transform = Transform3D(b, point)
