extends Node

var player: Player
var debug_text: RichTextLabel
var debug_text_array: Array[String]
var debug_text_array_max_length: int = 10

func setup_debug() -> void:
	debug_text_array = []
	player = get_tree().get_first_node_in_group("player")
	debug_text = player.get_node("hud/RichTextLabel")

func debug(string: String) -> void:
	print(string)
	if debug_text != null:
		if len(debug_text_array) > debug_text_array_max_length:
			debug_text_array.pop_back()
		debug_text_array.push_front(string)
		debug_text.text = ''
		for text in debug_text_array:
			debug_text.text += (text + '\n')
