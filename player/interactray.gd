extends RayCast3D

@onready var prompt = get_node('PromptLabel')
@onready var outline_material: Material = load("res://outlineMaterial.tres")

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
				generate_outline_for(detected)
				prompt.text = detected.item_name
				if Input.is_action_just_pressed("interact"):
					player.pickup_item(detected)
		if detected is Interactable:
			prompt.text = 'Interact'
			if Input.is_action_just_pressed("interact"):
				detected.interact()

func generate_outline_for(item: Item) -> void:
	if item.has_outline:
		return
	var meshes = item.find_children("*", "MeshInstance3D", true)
	for mesh_instance: MeshInstance3D in meshes:
		var mesh_outline: Mesh = mesh_instance.mesh.create_outline(0.01)
		var new_mesh: MeshInstance3D = MeshInstance3D.new()
		new_mesh.mesh = mesh_outline
		new_mesh.add_to_group("outlines")
		item.get_node("Deletables").add_child(new_mesh)
		new_mesh.set_surface_override_material(0, outline_material)
		item.has_outline = true
