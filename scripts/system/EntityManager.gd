extends Node
class_name EntityManager


static var _entity_container: Node2D

static var pop_effect: ParticleProfile = preload("res://assets/resources/particle_profiles/big_pop.tres")


func _ready() -> void:
	EventBus.ysort_ready.connect(_on_ysort_ready)
	GameState.game_state_changed.connect(_on_game_state_changed)


# -----------------------------------------------------------------------------------
# public api
# -----------------------------------------------------------------------------------

static func spawn(entity_type: StringName, pos: Vector2) -> Entity:
	EventBus.spawn_requested.emit(entity_type, pos)
	var entity: Entity = _instantiate(entity_type)
	if not entity:
		return null
	var random_offset: Vector2 = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	entity.global_position = pos + random_offset
	_add(entity)
	return entity

static func spawn_safely(entity_type: StringName, pos: Vector2) -> Entity:
	EventBus.spawn_requested.emit(entity_type, pos)
	var entity: Entity = _instantiate(entity_type)
	if not entity:
		return null
	var spawn_pos: Vector2 = WorldGrid.get_safe_world_pos(pos, CellType.TerrainType.GROUND)
	if spawn_pos == Vector2.INF:
		push_warning("EntityManager: no safe spawn found near %s, using raw pos" % pos)
		spawn_pos = pos
	entity.global_position = spawn_pos
	_add(entity)
	return entity
	
static func spawn_on_tile(entity_type: StringName, tile_pos: Vector2i) -> Entity:
	var pos: Vector2 = WorldGrid.tile_to_world(tile_pos)
	var entity: Entity = spawn_safely(entity_type, pos)
	return entity
	
static func spawn_as_player(entity_type: StringName, pos: Vector2) -> Entity:
	# this will need customized later to ensure that any creature can be spawned as a player
	var entity: Entity = spawn_safely(entity_type, pos)
	entity.ready.connect(PlayerManager.set_player.bind(entity), CONNECT_ONE_SHOT)
	
	return entity
	
# -----------------------------------------------------------------------------------
# internal
# -----------------------------------------------------------------------------------
	
func _on_game_state_changed(status: GameState.Status) -> void:
	if status == GameState.Status.LOADING:
		EntityRegistry.clear_cache()

func _on_ysort_ready(ysort: Node2D) -> void:
	_entity_container = ysort

static func _instantiate(entity_type: StringName) -> Entity:
	var instance = EntityRegistry.instantiate(entity_type)
	if not instance:
		push_error("EntityManager: failed to instantiate '%s'" % entity_type)
		return null
	if not instance is Entity:
		push_error("EntityManager: '%s' is not an Entity" % entity_type)
		instance.queue_free()
		return null
	return instance

static func _add(e: Entity) -> void:
	_entity_container.add_child.call_deferred(e)
	EventBus.entity_spawned.emit.call_deferred(e)
	if WorldGrid.is_world_pos_visible(e.global_position):
		ParticleManager.burst.call_deferred(pop_effect, e.global_position)
