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
func spawn_entity(entity: Entity, position: Vector2, z: float, safely: bool = true) -> void:
	if not entity.is_initialized:
		entity.initialize()
	var spawn_pos: Vector2 = get_safe_spawn_position(position, false) if safely else position
	if spawn_pos == Vector2.INF:
		Log.error("No ground tile found for spawn near %s" % position)
		return
	entity.global_position = spawn_pos + Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	entity.set_z_value(z)
	active_entities.append(entity)
	entity.tree_exiting.connect(_on_entity_left_tree.bind(entity), CONNECT_ONE_SHOT)
	var name_base: String = str(entity.basename) if entity.basename != &"" else entity.get_class()
	entity.name = "%s_%d" % [name_base, entity.get_instance_id()]
	_entity_container.add_child.call_deferred(entity)
	entity.is_spawned = true
	if entity.spawn_effect:
		entity.spawn_effect.execute(entity)
	entity.entity_spawned.emit.call_deferred()
	EventBus.entity_spawned.emit.call_deferred(entity)

func spawn_entity_at_tile(entity: Entity, tile: Vector2i, z: float, safely: bool = true) -> void:
	spawn_entity(entity, WorldGrid.tile_to_world(tile), z, safely)

func simple_spawn(entity_type: StringName, position: Vector2, safely: bool = true) -> Entity:
	var entity: Entity = create_entity(entity_type)
	spawn_entity(entity, position, 0, safely)
	return entity

func simple_spawn_tile(entity_type: StringName, tile: Vector2i, safely: bool = true) -> Entity:
	var entity: Entity = create_entity(entity_type)
	spawn_entity_at_tile(entity, tile, 0, safely)
	return entity

func _on_entity_left_tree(e: Entity) -> void:
	active_entities.erase(e)
	EventBus.entity_destroyed.emit(e)

func create_generic_entity() -> Entity:
	var e: Entity = Entity.new()
	e.ages = false
	e.render_shadow = false
	e.collision_layer = 0
	e.collision_mask = 0
	var col: CollisionShape2D = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = 1
	e.add_child(col)
	return e

func detach_entity(e: Entity) -> void:
	active_entities.erase(e)
	var cb: Callable = _on_entity_left_tree.bind(e)
	if e.tree_exiting.is_connected(cb):
		e.tree_exiting.disconnect(cb)
	if e.get_parent():
		e.get_parent().remove_child(e)


# ---------------------------------------------------------------------------------------------------
# utility
# ---------------------------------------------------------------------------------------------------

func get_safe_spawn_position(desired: Vector2, check_if_occupied: bool = true) -> Vector2:
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
				if not is_position_occupied(world) and check_if_occupied:
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
