## Autoload: EntityRegistry
##
## Scans [member SCAN_PATHS] for entity scenes ([code].tscn[/code]) at startup and
## builds a lookup from a [StringName] key (the scene's filename, without extension)
## to its resource path. Also indexes each entity's [CreatureArchetype] by rarity,
## tag, behavior class, consumer type, and locomotion so other systems can query
## "all entities matching X" without re-scanning the filesystem.
##
## Call [method scan_all] once at boot (see [code]AppController._ready()[/code])
## before any other system needs to spawn or look up an entity type.
extends Node


# -------------------------------------------------------
# directories scanned at startup.
# add mod paths here - res:// for builtin, user:// for 
# external packs dropped in by creators
# -------------------------------------------------------
## Directories scanned for entity scenes. Add mod paths here; [code]res://[/code]
## for built-in content, [code]user://[/code] for external packs dropped in by
## creators.
const SCAN_PATHS: Array[String] = [
	"res://scenes/entities/",
	"user://mods/entities/"
]

## Maps entity type key to its scene's resource path.
## [br]e.g. [code]&"gumbo" -> "res://scenes/entities/gumbo.tscn"[/code]
var registry: Dictionary = {}

## Instantiated [PackedScene] cache, populated lazily on first [method get_scene]
## call and cleared by [method clear_cache].
var _cache: Dictionary = {}

## Entity type key -> its [CreatureArchetype] resource, populated during
## [method scan_all].
var _archetypes: Dictionary[StringName, CreatureArchetype] = {}

## Entity type keys grouped by [enum CreatureArchetype.Rarity].
var _index_by_rarity: Dictionary[CreatureArchetype.Rarity, Array] = {}
## Entity type keys grouped by [enum CreatureArchetype.Tag].
var _index_by_tag: Dictionary[CreatureArchetype.Tag, Array] = {}
## Entity type keys grouped by [enum CreatureArchetype.BehaviorClass].
var _index_by_behavior: Dictionary[CreatureArchetype.BehaviorClass, Array] = {}
## Entity type keys grouped by [enum CreatureArchetype.ConsumerType].
var _index_by_consumer: Dictionary[CreatureArchetype.ConsumerType, Array] = {}
## Entity type keys grouped by [enum CreatureArchetype.Locomotion].
var _index_by_locomotion: Dictionary[CreatureArchetype.Locomotion, Array] = {}

## Emitted once [method scan_all] has finished scanning and indexing every
## entity scene.
signal all_entities_registered



# -----------------------------------------------------------------------------------
# public api
# -----------------------------------------------------------------------------------

## Returns the (cached) [PackedScene] for [param entity_type], loading it on
## first access. Returns [code]null[/code] and logs an error if the type is unknown.
func get_scene(entity_type: StringName) -> PackedScene:
	if not registry.has(entity_type):
		Log.error("Unknown entity type '%s'" % entity_type)
		return null
	if not _cache.has(entity_type):
		_cache[entity_type] = load(registry[entity_type])
	return _cache[entity_type]
	
## Instantiates a fresh [Node] for [param entity_type] via [method get_scene].
## Returns [code]null[/code] if the scene couldn't be found.
func instantiate(entity_type: StringName) -> Node:
	var scene := get_scene(entity_type)
	return scene.instantiate() if scene else null
	
## Clears the loaded-scene cache. Does not clear [member registry] or the
## archetype indices; call [method scan_all] for a full rescan.
func clear_cache() -> void:
	_cache.clear()
	
## Returns every registered entity type key.
func get_all_types() -> Array[StringName]:
	var types: Array[StringName] = []
	for key in registry:
		types.append(key)
	return types
	
## Clears the registry and all archetype indices, then rescans
## [member SCAN_PATHS] for entity scenes, registering each one found.
## Emits [signal all_entities_registered] when finished.
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


	

## Registers a single scanned scene under a key derived from its filename.
## [br]e.g. [code]"res://scenes/entities/pack_1/goober.tscn" -> &"goober"[/code]
## [br]Collision policy: first one found wins; duplicates are logged and skipped.
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

## Loads and instantiates [param scene_path] just long enough to read its
## [member Entity.archetype], then indexes that archetype by rarity, tag,
## behavior class, consumer type, and locomotion before freeing the instance.
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
	
## Returns the [CreatureArchetype] registered for [param entity_type], or
## [code]null[/code] if it has none or is unknown.
func get_archetype(entity_type: StringName) -> CreatureArchetype:
	return _archetypes.get(entity_type)
