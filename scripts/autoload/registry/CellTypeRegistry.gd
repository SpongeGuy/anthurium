## Autoload: CellTypeRegistry
##
## Scans [member SCAN_PATHS] for [CellType] resources ([code].tres[/code]) at
## startup and builds a lookup from a [StringName] key (the resource's
## filename, without extension) to its resource path. [WorldGrid] and
## [DungeonGenerator] use [method get_cell_type] to resolve a terrain name
## into the actual [CellType] resource.
extends Node
# autoload

## Directories scanned for cell type resources; [code]res://[/code] for
## built-in content, [code]user://[/code] for creator mods.
const SCAN_PATHS: Array[String] = [
	"res://assets/resources/cell_types/",
	"user://mods/cell_types/"
]

## Maps cell type key to its resource's path.
var registry: Dictionary[StringName, String] = {}
## Loaded [CellType] cache, populated lazily on first [method get_cell_type]
## call and cleared by [method clear_cache].
var _cache: Dictionary[StringName, CellType] = {}



## Emitted once [method scan_all] has finished registering every cell type.
signal all_tiles_registered

# ---------------------- public api ------------------------
# ---------------------------------------------------------

## Returns the (cached) [CellType] resource for [param cell_type], loading it
## on first access. Returns [code]null[/code] and pushes an engine error if
## the type is unknown.
func get_cell_type(cell_type: StringName) -> CellType:
	if not registry.has(cell_type):
		push_error("CellTypeRegistry: unknown type '%s'" % cell_type)
		return null
	if not _cache.has(cell_type):
		_cache[cell_type] = load(registry[cell_type])
	return _cache[cell_type]
	
## Clears the loaded-resource cache. Does not clear [member registry]; call
## [method scan_all] for a full rescan.
func clear_cache() -> void:
	_cache.clear()
	
## Returns every registered cell type key.
func get_all_types() -> Array[StringName]:
	var types: Array[StringName] = []
	for key in registry:
		types.append(key)
	return types









# -------------------- internal -------------------------------
# -----------------------------------------------------------

## Clears [member registry] and rescans [member SCAN_PATHS], registering
## every cell type resource found. Emits [signal all_tiles_registered] when
## finished.
func scan_all() -> void:
	registry.clear()
	ResourceScanner.scan(SCAN_PATHS, ".tres", _register)
	Log.info("%d cell types registered." % registry.size())
	all_tiles_registered.emit()
		
## Registers a single scanned resource under a key derived from its
## filename. First one found wins; duplicates are logged and skipped.
func _register(resource_path: String) -> void:
	var key: StringName = StringName(resource_path.get_file().get_basename())
	
	if registry.has(key):
		push_warning("CellTypeRegistry: duplicate key '%s'\n keeping: %s\n skipping: %s"
		% [key, registry[key], resource_path])
		return
	registry[key] = resource_path
