extends RayCast3D

@onready var prompt = get_node('PromptLabel')
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	add_exception(owner)

func _physics_process(_delta: float) -> void:
	prompt.text = ''
	if not player.is_holding:
		if is_colliding():
			var detected = get_collider()
			if detected is Interactable:
				prompt.text = 'Interact [E]'
				if Input.is_action_just_pressed("interact"):
					detected.interact()
			if detected is Holdable:
				prompt.text = 'Pickup [E]'
				if Input.is_action_just_pressed("interact"):
					player.hold_item(detected)
			if detected is Item:
				prompt.text = 'Pickup [E]'
				if Input.is_action_just_pressed("interact"):
					player.pickup_item(detected)
			else:
				prompt.text = 'NO!'
