extends Interactable

# node that we will be interacting with
@export var electronic : Node3D

func interact():
	electronic.interact()
