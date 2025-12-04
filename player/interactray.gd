extends RayCast3D

@onready var prompt = get_node('PromptLabel')

func _ready():
	add_exception(owner)

func check_interactions(player: Player) -> void:
	prompt.text = ''
	force_raycast_update()
	if is_colliding():
		prompt.text = 'Colliding'
		var detected = get_collider()
		if detected.is_in_group("item"):
			prompt.text = 'Hitbox'
			if detected is Item:
				prompt.text = detected.item_name
				if Input.is_action_just_pressed("interact"):
					player.pickup_item(detected)
		if detected is Interactable:
			prompt.text = 'Interact'
			if Input.is_action_just_pressed("interact"):
				detected.interact()
