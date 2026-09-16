extends BrainLobe
class_name LobePerceiveThreat

@export var radius: float = 128
@export var count_of_same_species: bool = false




func get_priority(entity: Entity) -> float:
	var brain: Brain = entity.get_component(Brain)
	var nearest: Entity = _find_nearest_threat(entity)
	brain.set_memory(Brain.Memory.THREAT, nearest)
	if not nearest:
		return 0
	
	var dist: float = SpatialUtil.get_distance_between_entities(entity, nearest)
	return remap(dist, radius, 0, 0, 1)


func _find_nearest_threat(entity: Entity) -> Entity:
	var nearby: Array[Entity] = SpatialUtil.get_entities_in_radius(entity.get_world_2d().direct_space_state, entity.global_position, radius, SpatialUtil.PhysicsLayers.CREATURES)
	if nearby.is_empty():
		return null
	
	var candidates: Array[Entity] = []
	for e in nearby:
		# don't count entity of the same species
		if e.basename == entity.basename and not count_of_same_species:
			continue
		# don't count entities that weigh less
		if e.mass < entity.mass:
			continue
		# don't count nonliving entities
		if not e.has_component(Brain):
			continue
		if not SpatialUtil.has_los_of(entity, e):
			continue
		candidates.append(e)
	
	if candidates.is_empty():
		return null
	
	return SpatialUtil.get_nearest_entity_in_array(entity.global_position, candidates)
