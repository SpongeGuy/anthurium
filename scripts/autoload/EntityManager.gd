extends Node
# audoload singleton!!!


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

const MAX_SPAWN_NUDGE_ATTEMPTS: int = 16
const SPAWN_NUDGE_DISTANCE: float = 10.0	

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

func scan_all() -> void:
	for path in SCAN_PATHS:
		if _path_exists(path):
			_scan_dir(path)
	all_entities_registered.emit()
	Log.info("%d entities registered." % registry.size())
	
func _scan_dir(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		Log.warn("Could not open path '%s'" % path)
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
		Log.warn("Duplicate key '%s'!\nKeeping: %s\nSkipping: %s" % [key, registry[key], scene_path])
		return
	registry[key] = scene_path



# -----------------------------------------------------------------------------------
# manager
# -----------------------------------------------------------------------------------

var _entity_container: Node2D
var pop_effect: ParticleProfile = load("uid://dmgf5tlac12go")


func spawn(entity_type: StringName, pos: Vector2) -> Entity:
	EventBus.spawn_requested.emit(entity_type, pos)
	var entity: Entity = _instantiate_entity(entity_type)
	if not entity:
		return null
	var random_offset: Vector2 = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	entity.global_position = pos + random_offset
	_add(entity)
	return entity

func spawn_safely(entity_type: StringName, pos: Vector2) -> Entity:
	EventBus.spawn_requested.emit(entity_type, pos)
	var entity: Entity = _instantiate_entity(entity_type)
	if not entity:
		return null
	var spawn_pos: Vector2 = WorldGrid.get_safe_world_pos(pos, CellType.TerrainType.GROUND)
	if spawn_pos == Vector2.INF:
		Log.warn("No safe spawn found near %s, using raw pos" % pos)
		spawn_pos = pos
	
	
	var attempts: int = 0
	while _is_position_occupied(spawn_pos) and attempts < MAX_SPAWN_NUDGE_ATTEMPTS:
		var angle: float = randf() * TAU
		spawn_pos += Vector2.from_angle(angle) * SPAWN_NUDGE_DISTANCE
		attempts += 1
		
	if attempts >= MAX_SPAWN_NUDGE_ATTEMPTS:
		Log.warn("Could not find unoccupied spawn near %s after %d attempts" % [pos, attempts])
	
	
	entity.global_position = spawn_pos
	_add(entity)
	return entity
	
func spawn_on_tile(entity_type: StringName, tile_pos: Vector2i) -> Entity:
	var pos: Vector2 = WorldGrid.tile_to_world(tile_pos)
	var entity: Entity = spawn_safely(entity_type, pos)
	return entity
	
func spawn_as_player(entity_type: StringName, pos: Vector2) -> Entity:
	# this will need customized later to ensure that any creature can be spawned as a player
	var entity: Entity = spawn_safely(entity_type, pos)
	entity.ready.connect(PlayerManager.set_player.bind(entity), CONNECT_ONE_SHOT)
	
	return entity
	
func _is_position_occupied(pos: Vector2) -> bool:
	var space_state: PhysicsDirectSpaceState2D = _entity_container.get_world_2d().direct_space_state
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask |= 8
	var result: Array[Dictionary] = space_state.intersect_point(query)
	return not result.is_empty()
	
# -----------------------------------------------------------------------------------
# internal
# -----------------------------------------------------------------------------------

func register_ysort_entity_container(ysort: Node2D) -> void:
	_entity_container = ysort
	Log.info("Registered %s as new entity container." % ysort)

func _instantiate_entity(entity_type: StringName) -> Entity:
	var instance = instantiate(entity_type)
	if not instance:
		push_error("EntityManager: failed to instantiate '%s'" % entity_type)
		return null
	if not instance is Entity:
		push_error("EntityManager: '%s' is not an Entity" % entity_type)
		instance.queue_free()
		return null
	return instance

func _add(e: Entity) -> void:
	_entity_container.add_child.call_deferred(e)
	EventBus.entity_spawned.emit.call_deferred(e)
	if WorldGrid.is_world_pos_visible(e.global_position):
		ParticleManager.burst.call_deferred(pop_effect, e.global_position)
