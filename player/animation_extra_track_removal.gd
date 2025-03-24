extends Node

func remove_end_animations(anim_player: AnimationPlayer):
	var animations_to_remove = []
	
	for anim_name in anim_player.get_animation_list():
		if "_end" in anim_name:
			animations_to_remove.append(anim_name)
	
	for anim_name in animations_to_remove:
		anim_player.remove_animation(anim_name)
		print("Removed animation:", anim_name)
	
	print("Cleanup complete. Removed", len(animations_to_remove), "animations.")

# Example usage:
# Call this function in `_ready()` or via a button, passing your AnimationPlayer node.
# remove_end_animations($AnimationPlayer)
