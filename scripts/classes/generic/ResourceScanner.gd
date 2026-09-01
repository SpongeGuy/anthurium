class_name ResourceScanner

static func scan(paths: Array[String], extension: String, on_file: Callable) -> void:
	for path in paths:
		
		if DirAccess.open(path) != null:
			_scan_dir(path, extension, on_file)
			
static func _scan_dir(path: String, extension: String, on_file: Callable) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		Log.error("Could not open path '%s'!" % path)
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full_path: String = path.path_join(entry)
		if dir.current_is_dir():
			_scan_dir(full_path + "/", extension, on_file)
		elif entry.ends_with(extension):
			on_file.call(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
