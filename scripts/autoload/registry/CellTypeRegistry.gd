extends Node
# autoload

const SCAN_PATHS: Array[String] = [
	"res://assets/resources/cell_types/",
	"user://mods/cell_types/"
]

var registry: Dictionary[StringName, String] = {}
# StringName -> Resource (populated on first use)
var _cache: Dictionary[StringName, CellType] = {}



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

func scan_all() -> void:
	registry.clear()
	ResourceScanner.scan(SCAN_PATHS, ".tres", _register)
	Log.info("%d cell types registered." % registry.size())
	all_tiles_registered.emit()
		

func _register(resource_path: String) -> void:
	var key: StringName = StringName(resource_path.get_file().get_basename())
	
	if registry.has(key):
		push_warning("CellTypeRegistry: duplicate key '%s'\n keeping: %s\n skipping: %s"
		% [key, registry[key], resource_path])
		return
	registry[key] = resource_path
