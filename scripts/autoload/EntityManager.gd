extends Node
# EntityManager autoload

const FREE_SEARCH_RADIUS: int = 3
const SPAWN_CLEARANCE: float = 12

var _entity_container: Node2D
var active_entities: Array[Entity] = []

func register_ysort_entity_container(ysort: Node2D) -> void:
	_entity_container = ysort
	Log.info("Registered %s as new entity container." % ysort)








# ---------------------------------------------------------------------------------------------------
# main functions
# ---------------------------------------------------------------------------------------------------

func destroy_all_entities() -> void:
	for i in range(active_entities.size() - 1, -1, -1):
		active_entities[i].queue_free()

func create_entity(entity_type: StringName) -> Entity:
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
	instance.initialize()
	return instance

## packages an entity
func package_entity_into_portal(entity: Entity) -> Entity:
	var portal: Entity = create_entity(&"portal")
	if not portal.is_initialized:
		await portal.entity_initialized
	var p_component: PortalComponent = portal.get_component(PortalComponent)
	p_component.add_entity(entity)
	return portal

func attach_key_to_entity(entity: Entity) -> Entity:
	return null

## takes in an Entity and adds it to the world at a given position and z.
## offsets entity very slightly to prevent infinite collisions with other entities.
## set safely to false to prevent checking for a valid ground location.
func spawn_entity(entity: Entity, position: Vector2, z: float, as_player: bool = false, safely: bool = true) -> void:
	if not entity.is_initialized:
		entity.initialize()
	var spawn_pos: Vector2 = get_safe_spawn_position(position) if safely else position
	if spawn_pos == Vector2.INF:
		Log.error("No ground tile found for spawn near %s" % position)
		return
	entity.global_position = spawn_pos + Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	entity.set_z_value(z)
	active_entities.append(entity)
	if as_player:
		PlayerManager.set_player(entity)
	entity.tree_exiting.connect(_on_entity_left_tree.bind(entity), CONNECT_ONE_SHOT)
	_entity_container.add_child.call_deferred(entity)
	entity.is_spawned = true
	entity.entity_spawned.emit.call_deferred()
	EventBus.entity_spawned.emit.call_deferred(entity)

func spawn_entity_at_tile(entity: Entity, tile: Vector2i, z: float, as_player: bool = false, safely: bool = true) -> void:
	spawn_entity(entity, WorldGrid.tile_to_world(tile), z, as_player, safely)

func _on_entity_left_tree(e: Entity) -> void:
	active_entities.erase(e)
	EventBus.entity_destroyed.emit(e)


# ---------------------------------------------------------------------------------------------------
# utility
# ---------------------------------------------------------------------------------------------------

func get_safe_spawn_position(desired: Vector2) -> Vector2:
	var origin: Vector2i = WorldGrid.world_to_tile(desired).clamp(Vector2i.ZERO, Vector2i(WorldGrid.width - 1, WorldGrid.height - 1))
	var max_r: int = maxi(WorldGrid.width, WorldGrid.height)
	var fallback: Vector2 = Vector2.INF # nearest ground tile, even if occupied
	for r in range(max_r + 1):
		if r > FREE_SEARCH_RADIUS and fallback != Vector2.INF:
			break
		for dx in range(-r, r+1):
			for dy in range(-r, r+1):
				if maxi(absi(dx), absi(dy)) != r: # ring only
					continue
				var tile: Vector2i = origin + Vector2i(dx, dy)
				if not _is_ground_tile(tile):
					continue
				var world: Vector2 = WorldGrid.tile_to_world(tile)
				if fallback == Vector2.INF:
					fallback = world
				if not is_position_occupied(world):
					return world
	return fallback

func _is_ground_tile(tile: Vector2i) -> bool:
	if tile.x < 0 or tile.y < 0 or tile.x >= WorldGrid.width or tile.y >= WorldGrid.height:
		return false
	var cell: CellData = WorldGrid.get_cell(tile)
	return cell != null and cell.type.terrain == CellType.TerrainType.GROUND
	

func is_position_occupied(position: Vector2) -> bool:
	# entities spawned earlier this frame aren't in the physics space yet
	for e: Entity in active_entities:
		if is_instance_valid(e) and e.global_position.distance_to(position) < SPAWN_CLEARANCE:
			return true
	# other physics bodies
	if _entity_container == null:
		return false
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = SpatialUtil.PhysicsLayers.CREATURES
	return not _entity_container.get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()



