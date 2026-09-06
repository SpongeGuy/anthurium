## Autoload: EntityManager
##
## Spawns and tracks every live [Entity] in the world. Wraps
## [EntityRegistry].instantiate() with placement logic (safe/unoccupied
## spawn positions, spawn-jitter, portal spawn tables), keeps
## [member active_entities] up to date, and fires the associated spawn
## effects/sounds.
extends Node
# audoload singleton!!!


## Max number of times [method spawn_safely]/[method spawn_portal] will nudge
## a spawn position sideways to find an unoccupied spot.
const MAX_SPAWN_NUDGE_ATTEMPTS: int = 16
## Distance, in pixels, each nudge attempt moves the candidate spawn position.
const SPAWN_NUDGE_DISTANCE: float = 12.0


# -----------------------------------------------------------------------------------
# manager
# -----------------------------------------------------------------------------------

## The [Node2D] new entities are parented under. Set by
## [method register_ysort_entity_container].
var _entity_container: Node2D
## Particle effect burst on every successful spawn (see [method _add]).
var pop_effect: ParticleProfile = load("uid://dmgf5tlac12go")
## Sound played on spawn when requested (see [method spawn]/[method spawn_safely]).
var poof_sound: VoiceProfile = load("uid://dgiuplfa2wr8m")

## Every currently live entity.
var active_entities: Array[Entity] = []

## Frees every active entity (iterated in reverse so removal from
## [member active_entities] during [signal Node.tree_exiting] doesn't skip
## entries).
func destroy_all() -> void:
	for i in range(active_entities.size() - 1, -1, -1):
		active_entities[i].queue_free()


## Spawns [param entity_type] at [param pos] with a small random position
## jitter (no occupancy check — see [method spawn_safely] for that).
## Emits [signal EventBus.spawn_requested] before instantiation. Plays
## [member poof_sound] unless [param play_sound] is [code]false[/code].
func spawn(entity_type: StringName, pos: Vector2, play_sound: bool = true, z: float = 0) -> Entity:
	EventBus.spawn_requested.emit(entity_type, pos)
	var entity: Entity = _instantiate_entity(entity_type)
	if not entity:
		return null
	var random_offset: Vector2 = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	entity.global_position = pos + random_offset
	entity.set_z_value(z)
	_add(entity)
	
	if play_sound:
		AudioManager.play_voice(poof_sound, entity)
	return entity
	
## Spawns a [code]&"portal"[/code] entity near [param pos], configured with
## [param spawn_table] (duplicated so each portal has its own copy). Finds a
## safe ground position near [param pos] and nudges away from any occupied
## spot before placing it.
func spawn_portal(pos: Vector2, spawn_table: SpawnTable) -> Entity:
	var portal: Entity = _instantiate_entity(&"portal")
	var spawner: SpawnTableSpawnerComponent = portal.get_component(SpawnTableSpawnerComponent)
	spawner.spawn_table = spawn_table.duplicate()
	
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
	
	portal.global_position = spawn_pos
	_add(portal)
	return portal

## Spawns [param entity_type] near [param pos], finding a safe ground
## position and nudging away from any occupied spot before placing it. Plays
## [member poof_sound] unless [param play_sound] is [code]false[/code]. This
## is the preferred spawn method for anything that shouldn't land on
## impassable terrain or overlap another entity.
func spawn_safely(entity_type: StringName, pos: Vector2, play_sound: bool = true) -> Entity:
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
	if play_sound:
		AudioManager.play_voice(poof_sound, entity)
	return entity
	
## Convenience wrapper around [method spawn_safely] that takes a tile
## coordinate instead of a world position.
func spawn_on_tile(entity_type: StringName, tile_pos: Vector2i) -> Entity:
	var pos: Vector2 = WorldGrid.tile_to_world(tile_pos)
	var entity: Entity = spawn_safely(entity_type, pos)
	return entity
	
## Spawns [param entity_type] via [method spawn_safely] and hands control of
## it to [PlayerManager] as soon as it's ready.
func spawn_as_player(entity_type: StringName, pos: Vector2) -> Entity:
	# this will need customized later to ensure that any creature can be spawned as a player
	var entity: Entity = spawn_safely(entity_type, pos)
	entity.ready.connect(PlayerManager.set_player.bind(entity), CONNECT_ONE_SHOT)
	
	return entity
	
## Returns whether any physics body occupies [param pos] (used to avoid
## spawning entities on top of each other).
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

## Sets [param ysort] as the parent all spawned entities are added under.
## Must be called once per world/scene before any entity is spawned.
func register_ysort_entity_container(ysort: Node2D) -> void:
	_entity_container = ysort
	Log.info("Registered %s as new entity container." % ysort)

## Loads and instantiates [param entity_type] via [EntityRegistry], validating
## that the type is non-blank, actually exists, and is an [Entity] (freeing
## and rejecting the instance otherwise). Returns [code]null[/code] on any
## failure, with an error logged.
func _instantiate_entity(entity_type: StringName) -> Entity:
	if entity_type == "":
		Log.error("Given blank entity_type, aborting entity instantiation.")
		return null
		
	var instance = EntityRegistry.instantiate(entity_type)
	if not instance:
		Log.error("Failed to instantiate '%s'" % entity_type)
		return null
	if not instance is Entity:
		Log.error("EntityManager: '%s' is not an Entity" % entity_type)
		instance.queue_free()
		return null
	return instance

## Registers [param e] as active, parents it under [member _entity_container]
## (deferred), wires cleanup on [signal Node.tree_exiting], emits
## [signal EventBus.entity_spawned], and bursts [member pop_effect] if the
## spawn point is currently visible.
func _add(e: Entity, z: float = 0) -> void:
	active_entities.append(e)
	e.tree_exiting.connect(_on_tree_exiting.bind(e), CONNECT_ONE_SHOT)
	_entity_container.add_child.call_deferred(e)
	EventBus.entity_spawned.emit.call_deferred(e)
	if WorldGrid.is_world_pos_visible(e.global_position):
		ParticleManager.burst.call_deferred(pop_effect, e.global_position)
	
	Log.debug("Spawned new %s at %s" % [e, e.global_position])

## Connected to each entity's [signal Node.tree_exiting]; removes [param e]
## from [member active_entities] and emits [signal EventBus.entity_destroyed].
func _on_tree_exiting(e: Entity) -> void:
	active_entities.erase(e)
	EventBus.entity_destroyed.emit()
