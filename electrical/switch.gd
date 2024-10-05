extends Interactable

@export var electronics : Array[Node3D] = []

func interact():
	get_node("SwitchOnStream").play()
	for electronic in electronics:
		electronic.interact()
