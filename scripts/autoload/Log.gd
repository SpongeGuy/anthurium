extends Node

enum LogType {DEBUG, INFO, WARN, ERROR }

var min_level: LogType = LogType.DEBUG

var log_to_file: bool = false
var log_file_path: String = "user://game.log"
var _file: FileAccess

func initialize() -> void:
	if log_to_file:
		_file = FileAccess.open(log_file_path, FileAccess.WRITE)
		
	var start_line: String = "=== Log started at %s ===" % _get_time_string()
	print(start_line)
	if log_to_file and _file:
		_file.store_line(start_line)
	
	
func debug(message: String) -> void:
	_log(LogType.DEBUG, message)
	
func info(message: String) -> void:
	_log(LogType.INFO, message)
	
func warn(message: String) -> void:
	_log(LogType.WARN, message)
	
func error(message: String) -> void:
	_log(LogType.ERROR, message)
	
func _log(type: LogType, message: String) -> void:
	if type < min_level:
		return
		
	var time_str := _format_game_time(AppController.time)
	var script_name := _get_caller_name()
	var line := "[%s][%s]: %s" % [time_str, script_name, message]
	
	match type:
		LogType.DEBUG:
			print_rich("[color=aquamarine]%s[/color]" % line)
		LogType.WARN:
			push_warning(line)
			print_rich("[color=yellow]%s[/color]" % line)
		LogType.ERROR:
			push_error(line)
			print_rich("[color=tomato]%s[/color]" % line)
		_:
			print(line)
	if log_to_file and _file:
		_file.store_line(line)
		
func _get_time_string() -> String:
	var time_dict := Time.get_time_dict_from_system()
	var unix_time := Time.get_unix_time_from_system()
	var ms := int(fmod(unix_time, 1.0) * 1000)
	return "%02d:%02d:%02d.%03d" % [
		time_dict["hour"],
		time_dict["minute"],
		time_dict["second"],
		ms
	]
		

func _get_caller_name() -> String:
	var stack := get_stack()
	if stack.size() > 3:
		var source: String = stack[3]["source"]
		return source.get_file().get_basename()
	return "Unknown"

func _format_game_time(seconds: float) -> String:
	var total_ms := int(round(seconds * 1000.0))
	var ms := total_ms % 1000
	var total_seconds := total_ms / 1000
	var s := total_seconds % 60
	var total_minutes := total_seconds / 60
	var m := total_minutes % 60
	var h := total_minutes / 60
	return "%02d:%02d:%02d.%03d" % [h, m, s, ms]
