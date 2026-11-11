class_name ResourceScanner

static func scan(paths: Array[String], extension: String, on_file: Callable) -> void:
	for path in paths:
		var dir_path: String = path if path.ends_with("/") else path + "/"
		if dir_path.begins_with("res://"):
			_scan_res_dir(dir_path, extension, on_file)
		elif DirAccess.dir_exists_absolute(dir_path):
			_scan_disk_dir(dir_path, extension, on_file)

static func _scan_res_dir(path: String, extension: String, on_file: Callable) -> void:
	for entry: String in ResourceLoader.list_directory(path):
		if entry.ends_with("/"):
			_scan_res_dir(path + entry, extension, on_file)
		elif entry.ends_with(extension):
			on_file.call(path + entry)

static func _scan_disk_dir(path: String, extension: String, on_file: Callable) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		Log.error("Could not open path '%s'!" % path)
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			_scan_disk_dir(path.path_join(entry) + "/", extension, on_file)
		elif entry.ends_with(extension):
			on_file.call(path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
