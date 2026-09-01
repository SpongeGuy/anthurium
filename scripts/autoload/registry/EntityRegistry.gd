extends Node


# -------------------------------------------------------
# directories scanned at startup.
# add mod paths here - res:// for builtin, user:// for 
# external packs dropped in by creators
# -------------------------------------------------------
const SCAN_PATHS: Array[String] = [
	"res://scenes/entities/",
	"user://mods/entities/"
]

# StringName -> resource path
# e.g. &"gumbo" -> "res://scenes/entities/gumbo.tscn"
var registry: Dictionary = {}

# StringName -> PackedScene (populated on first spawn, cleared on reset)
var _cache: Dictionary = {}

signal all_entities_registered



# -----------------------------------------------------------------------------------
# public api
# -----------------------------------------------------------------------------------

func get_scene(entity_type: StringName) -> PackedScene:
	if not registry.has(entity_type):
		Log.error("Unknown entity type '%s'" % entity_type)
		return null
	if not _cache.has(entity_type):
		_cache[entity_type] = load(registry[entity_type])
	return _cache[entity_type]
	
func instantiate(entity_type: StringName) -> Node:
	var scene := get_scene(entity_type)
	return scene.instantiate() if scene else null
	
func clear_cache() -> void:
	_cache.clear()
	
func get_all_types() -> Array[StringName]:
	var types: Array[StringName] = []
	for key in registry:
		types.append(key)
	return types


# -----------------------------------------------------------------------------------
# scanning
# -----------------------------------------------------------------------------------

func scan_all() -> void:
	registry.clear()
	ResourceScanner.scan(SCAN_PATHS, ".tscn", _register)
	all_entities_registered.emit()
	Log.info("%d entities registered." % registry.size())
	

func _register(scene_path: String) -> void:
	# key is the filename without extension
	# "res://scenes/entities/pack_1/goober.tscn" -> &"goober"
	# collision policy: first one found wins, warn on duplicates
	var key: StringName = StringName(scene_path.get_file().get_basename())
	
	if registry.has(key):
		Log.warn("Duplicate key '%s'!\nKeeping: %s\nSkipping: %s" % [key, registry[key], scene_path])
		return
	registry[key] = scene_path
