extends Node
# audoload singleton!!!


# -------------------------------------------------------
# directories scanned at startup.
# add mod paths here - res:// for builtin, user:// for 
# external packs dropped in by creators
# -------------------------------------------------------
const SCAN_PATHS: Array[String] = [
	"res://scenes/entities/",
	"user://mods/"
]

# StringName -> resource path
# e.g. &"gumbo" -> "res://scenes/entities/gumbo.tscn"
var registry: Dictionary = {}

# StringName -> PackedScene (populated on first spawn, cleared on reset)
var _cache: Dictionary = {}


func _ready() -> void:
	_scan_all()
	

# -----------------------------------------------------------------------------------
# public api
# -----------------------------------------------------------------------------------

func get_scene(entity_type: StringName) -> PackedScene:
	if not registry.has(entity_type):
		push_error("EntityRegistry: unknown type '%s'" % entity_type)
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

func _scan_all() -> void:
	for path in SCAN_PATHS:
		if _path_exists(path):
			_scan_dir(path)
	print("EntityRegistry: %d entities registered." % registry.size())
	
func _scan_dir(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		push_warning("EntityRegistry: could not open path '%s'" % path)
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	
	while entry != "":
		var full_path: String = path.path_join(entry)
		
		if dir.current_is_dir():
			# recurse into subdirectories; pack_1/, pack_2/, etc.
			_scan_dir(full_path + "/")
		elif entry.ends_with(".tscn"):
			_register(full_path)
			
		entry = dir.get_next()
		
	dir.list_dir_end()

func _path_exists(path: String) -> bool:
	# DirAccess.open returns null for missing paths, we'll use that as the check
	return DirAccess.open(path) != null

func _register(scene_path: String) -> void:
	# key is the filename without extension
	# "res://scenes/entities/pack_1/goober.tscn" -> &"goober"
	# collision policy: first one found wins, warn on duplicates
	var key: StringName = StringName(scene_path.get_file().get_basename())
	
	if registry.has(key):
		push_warning(
			"EntityRegistry: duplicate key '%s'\n keeping: %s\n skipping: %s"
			% [key, registry[key], scene_path]
		)
		return
	registry[key] = scene_path
