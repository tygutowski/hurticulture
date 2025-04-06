extends RayCast3D

@onready var prompt = get_node('PromptLabel')

func _ready():
	add_exception(owner)

func check_interactions(player: Player) -> void:
	prompt.text = ''
	force_raycast_update()
	if is_colliding():
		var detected = get_collider()
		if detected.is_in_group("item_hitbox"):
			var item = detected.get_parent()
			if item is Item:
				prompt.text = 'Pickup'
				if Input.is_action_just_pressed("interact"):
					player.pickup_item(item)
		if detected is Interactable:
			prompt.text = 'Interact'
			if Input.is_action_just_pressed("interact"):
				detected.interact()
