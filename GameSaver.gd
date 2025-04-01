extends Node
class_name GameSaver

var save_path: String = "user://hurticulture/saves/"

func save_game_state() -> void:
	# automatically saves game data when instancing
	var host_game_state: HostGameState = HostGameState.new()
	var save_name: String = save_path + get_time() + ".tscn"
	ResourceSaver.save(host_game_state, save_name)
	Debug.debug("saving as " + save_name)

func get_time() -> String:
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	var year:   String = str(datetime["year"]).substr(2)
	var month:  String = str(datetime["month"])
	var day:    String = str(datetime["day"])
	var hour:   String = str(datetime["hour"])
	var minute: String = str(datetime["minute"])
	var formatted_datetime: String = "sv_" + month + "." + day + "." + year.substr(0, 2) + "_" + hour + ":" + minute
	return(formatted_datetime)

func load_game_state(file_path: String) -> void:
	var host_game_state: HostGameState = load(file_path) as HostGameState
