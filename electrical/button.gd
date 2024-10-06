extends Interactable

# node that we will be interacting with
@export var electronics : Array[Node3D] = []

func interact():
	for electronic in electronics:
		electronic.interact()
