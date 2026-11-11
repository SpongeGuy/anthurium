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


var registry: Dictionary = {}
var _cache: Dictionary = {}
var _archetypes: Dictionary[StringName, CreatureArchetype] = {}

var _index_by_rarity: Dictionary[CreatureArchetype.Rarity, Array] = {}
var _index_by_tag: Dictionary[CreatureArchetype.Tag, Array] = {}
var _index_by_behavior: Dictionary[CreatureArchetype.BehaviorClass, Array] = {}
var _index_by_consumer: Dictionary[CreatureArchetype.ConsumerType, Array] = {}
var _index_by_locomotion: Dictionary[CreatureArchetype.Locomotion, Array] = {}

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
	
## Returns every registered entity type key.
func get_all_types() -> Array[StringName]:
	var types: Array[StringName] = []
	for key in registry:
		types.append(key)
	return types

func scan_all() -> void:
	registry.clear()
	_archetypes.clear()
	_index_by_rarity.clear()
	_index_by_tag.clear()
	_index_by_behavior.clear()
	_index_by_consumer.clear()
	_index_by_locomotion.clear()
	ResourceScanner.scan(SCAN_PATHS, ".tscn", _register)
	all_entities_registered.emit()
	Log.info("%d entities registered." % registry.size())


# -----------------------------------------------------------------------------------
# scanning
# -----------------------------------------------------------------------------------

func _register(scene_path: String) -> void:
	# key is the filename without extension
	# "res://scenes/entities/pack_1/goober.tscn" -> &"goober"
	# collision policy: first one found wins, warn on duplicates
	var key: StringName = StringName(scene_path.get_file().get_basename())
	
	if registry.has(key):
		Log.warn("Duplicate key '%s'!\nKeeping: %s\nSkipping: %s" % [key, registry[key], scene_path])
		return
	registry[key] = scene_path
	_index_archetype(key, scene_path)


func _index_archetype(key: StringName, scene_path: String) -> void:
	var scene: PackedScene = load(scene_path)
	_cache[key] = scene
	var instance: Entity = scene.instantiate()
	if instance.archetype:
		_archetypes[key] = instance.archetype
		_index_by_rarity.get_or_add(instance.archetype.rarity, []).append(key)
		for tag in instance.archetype.tags:
			_index_by_tag.get_or_add(tag, []).append(key)
		_index_by_behavior.get_or_add(instance.archetype.behavior_class, []).append(key)
		_index_by_consumer.get_or_add(instance.archetype.consumer_type, []).append(key)
		_index_by_locomotion.get_or_add(instance.archetype.locomotion, []).append(key)
	instance.free()
	

func get_archetype(entity_type: StringName) -> CreatureArchetype:
	return _archetypes.get(entity_type)
