extends Node
# autoload

const SCAN_PATHS: Array[String] = [
	"res://assets/resources/cell_types/",
	"user://mods/cell_types/"
]

var registry: Dictionary[StringName, String] = {}
# StringName -> Resource (populated on first use)
var _cache: Dictionary[StringName, CellType] = {}

func _ready() -> void:
	_scan_all()

signal all_tiles_registered

# ---------------------- public api ------------------------
# ---------------------------------------------------------

func get_cell_type(cell_type: StringName) -> CellType:
	if not registry.has(cell_type):
		push_error("CellTypeRegistry: unknown type '%s'" % cell_type)
		return null
	if not _cache.has(cell_type):
		_cache[cell_type] = load(registry[cell_type])
	return _cache[cell_type]
	
func clear_cache() -> void:
	_cache.clear()
	
func get_all_types() -> Array[StringName]:
	var types: Array[StringName] = []
	for key in registry:
		types.append(key)
	return types









# -------------------- internal -------------------------------
# -----------------------------------------------------------

func _scan_all() -> void:
	for path in SCAN_PATHS:
		if _path_exists(path):
			_scan_dir(path)
	print("CellTypeRegistry: %d cell types registered." % registry.size())
	all_tiles_registered.emit()
	
func _path_exists(path: String) -> bool:
	return DirAccess.open(path) != null
	
func _scan_dir(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		push_warning("CellTypeRegistry: could not open path '%s'" % path)
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	
	while entry != "":
		var full_path: String = path.path_join(entry)
		if dir.current_is_dir():
			# recursive scan
			_scan_dir(full_path + "/")
		elif entry.ends_with(".tres"):
			_register(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	

func _register(resource_path: String) -> void:
	var key: StringName = StringName(resource_path.get_file().get_basename())
	
	if registry.has(key):
		push_warning("CellTypeRegistry: duplicate key '%s'\n keeping: %s\n skipping: %s"
		% [key, registry[key], resource_path])
		return
	registry[key] = resource_path
