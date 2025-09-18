extends Node

func find_children_in_group(group_name: String, parent: Node) -> Array:
	var matches = []
	for child in parent.get_children():
		if child.is_in_group(group_name):
			matches.append(child)
		matches += find_children_in_group(group_name, child)
	return matches
