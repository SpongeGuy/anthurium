class_name SpatialUtil

static func random_offset(min_distance: float, max_distance: float, min_angle: float = 0, max_angle: float = TAU) -> Vector2:
	var angle: float = randf_range(min_angle, max_angle)
	var distance: float = randf_range(min_distance, max_distance)
	return Vector2.from_angle(angle) * distance
	
static func random_position(origin: Vector2, min_distance: float, max_distance: float, min_angle: float = 0, max_angle: float = TAU) -> Vector2:
	return origin + random_offset(min_distance, max_distance, min_angle, max_angle)


static var _query_shape: CircleShape2D = CircleShape2D.new()

enum PhysicsLayers {
	TERRAIN = 1 << 0,
	CREATURES = 1 << 1,
	ITEMS = 1 << 2,
	PROJECTILES = 1 << 3,
	PLANTS = 1 << 4,
	TERRAIN_LOW = 1 << 8,
}

const LOW_TERRAIN_CLEARANCE: int = 3
const MAX_NUDGE_ATTEMPTS: int = 15

static func get_entities_in_radius(space_state: PhysicsDirectSpaceState2D, position: Vector2, radius: float, collision_mask: int = 0xFFFFFFFF) -> Array[Entity]:
	_query_shape.radius = radius

	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = _query_shape
	query.transform = Transform2D(0.0, position)
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var results: Array[Dictionary] = space_state.intersect_shape(query, 64)

	var seen: Dictionary[Entity, bool] = {}
	var entities: Array[Entity] = []
	for result in results:
		var entity: Entity = Entity.find_entity(result["collider"])
		if entity and not seen.has(entity):
			seen[entity] = true
			entities.append(entity)
	return entities
	


## Returns whether two vertical spans overlap, where each span runs from
## its given bottom ([param z_min_a]/[param z_min_b]) up to bottom + height.
## Used to decide whether two z-extended things (an [Entity]'s body, a
## [Hitbox]/[Hurtbox]'s damage volume, etc.) actually occupy the same
## altitude, independent of their 2D footprint.
static func z_ranges_overlap(z_min_a: float, height_a: float, z_min_b: float, height_b: float) -> bool:
	return z_min_a < z_min_b + height_b and z_min_b < z_min_a + height_a

static func get_safe_location(position: Vector2) -> Vector2:
	var pos: Vector2 = WorldGrid.get_safe_world_pos(position, CellType.TerrainType.WALL)
	return pos
	
	

static func get_safe_location_relative(position: Vector2, min_distance: float, max_distance: float) -> Vector2:
	var pos: Vector2 = random_position(position, min_distance, max_distance)
	pos = WorldGrid.get_safe_world_pos(pos, CellType.TerrainType.WALL)
	return pos


static func raycast_hits_terrain(space_state: PhysicsDirectSpaceState2D, origin: Vector2, target: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin, target)
	query.collision_mask = PhysicsLayers.TERRAIN | PhysicsLayers.TERRAIN_LOW
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var result: Dictionary = space_state.intersect_ray(query)
	return not result.is_empty()


static func get_entities_in_cone(space_state: PhysicsDirectSpaceState2D, origin: Vector2, direction: Vector2, radius: float, angle: float, collision_mask: int = PhysicsLayers.CREATURES) -> Array[Entity]:
	var candidates: Array[Entity] = get_entities_in_radius(space_state, origin, radius, collision_mask)

	var forward: Vector2 = direction.normalized()
	var half_angle: float = angle * 0.5

	var entities: Array[Entity] = []
	for entity in candidates:
		var to_entity: Vector2 = entity.global_position - origin
		if to_entity.is_zero_approx():
			continue
		if absf(forward.angle_to(to_entity)) <= half_angle:
			entities.append(entity)
	return entities
