## Autoload: Log
##
## Project-wide logger. Prefixes each message with the in-game time
## ([member AppController.time]) and the name of the calling script, colors
## output by severity via [method @GlobalScope.print_rich], and optionally
## mirrors every line to a log file on disk.
##
## Call [method initialize] once at boot (before anything else logs); see
## [code]AppController._ready()[/code].
extends Node

## Severity levels, in ascending order. Messages below [member min_level] are
## dropped.
enum LogType {DEBUG, INFO, WARN, ERROR }

## Minimum severity that will actually be logged.
var min_level: LogType = LogType.DEBUG

## If [code]true[/code], every logged line is also appended to
## [member log_file_path].
var log_to_file: bool = false
## Path the log file is written to when [member log_to_file] is enabled.
var log_file_path: String = "user://game.log"
var _file: FileAccess

## Opens [member log_file_path] for writing if [member log_to_file] is set,
## and prints/writes a session-start banner. Must be called once at boot
## before any other [Log] method.
func initialize() -> void:
	if log_to_file:
		_file = FileAccess.open(log_file_path, FileAccess.WRITE)
		
	var start_line: String = "=== Log started at %s ===" % _get_time_string()
	print(start_line)
	if log_to_file and _file:
		_file.store_line(start_line)
	
	
## Logs [param message] at [constant LogType.DEBUG].
func debug(message: String) -> void:
	_log(LogType.DEBUG, message)
	
## Logs [param message] at [constant LogType.INFO].
func info(message: String) -> void:
	_log(LogType.INFO, message)
	
## Logs [param message] at [constant LogType.WARN]. Also raises an editor
## warning via [method @GlobalScope.push_warning].
func warn(message: String) -> void:
	_log(LogType.WARN, message)
	
## Logs [param message] at [constant LogType.ERROR]. Also raises an editor
## error via [method @GlobalScope.push_error].
func error(message: String, critital: bool = false) -> void:
	_log(LogType.ERROR, message)
	if critital:
		assert(false, message)
	
## Formats and emits a single log line if [param type] meets
## [member min_level], colorizing by severity and writing to
## [member log_file_path] if file logging is enabled.
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
			print_rich("[color=lavender]%s[/color]" % line)
	if log_to_file and _file:
		_file.store_line(line)
		
## Returns the current wall-clock time as [code]HH:MM:SS.mmm[/code], used
## for the session-start banner.
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
		

## Walks the call stack to find the name of the script that called into
## [Log] (skipping [Log]'s own frames), so each line can be tagged with its
## source. Returns [code]"Unknown"[/code] if the stack is too shallow.
func _get_caller_name() -> String:
	var stack := get_stack()
	if stack.size() > 3:
		var source: String = stack[3]["source"]
		return source.get_file().get_basename()
	return "Unknown"

## Formats [param seconds] of in-game time as [code]HH:MM:SS.mmm[/code].
func _format_game_time(seconds: float) -> String:
	var total_ms := int(round(seconds * 1000.0))
	var ms := total_ms % 1000
	var total_seconds := total_ms / 1000
	var s := total_seconds % 60
	var total_minutes := total_seconds / 60
	var m := total_minutes % 60
	var h := total_minutes / 60
	return "%02d:%02d:%02d.%03d" % [h, m, s, ms]
