extends Node

var player: Player
var debug_text: RichTextLabel
var debug_text_array: Array[String]
var debug_text_array_max_length: int = 10

func setup_debug() -> void:
	debug_text_array = []


func debug(string) -> void:
	if player == null:
		return
	string = str(string)
	if debug_text != null:
		if len(debug_text_array) > debug_text_array_max_length:
			debug_text_array.pop_back()
		debug_text_array.push_front(string)
		debug_text.text = ''
		for text in debug_text_array:
			debug_text.text += (text + '\n')
