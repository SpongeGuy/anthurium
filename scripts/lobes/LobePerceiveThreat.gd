extends BrainLobe
class_name LobePerceiveThreat

@export var radius: float = 128
@export var count_same_species: bool = false
@export var physics_layer: SpatialUtil.PhysicsLayers = SpatialUtil.PhysicsLayers.CREATURES
@export_enum("Circular", "Cone") var detection_type: int = 0
@export var cone_angle: float = 30

@export var threat_exceptions: Dictionary = {
	"same_species": true,
	"weigh_less": true,
	"isnt_passive": true,
	"has_brain": true,
	"has_LOS": true,
}




func get_priority(entity: Entity) -> float:
	var brain: Brain = entity.get_component(Brain)
	var nearest: Entity = _find_nearest_threat(entity)
	brain.set_memory(Brain.Memory.THREAT, nearest)
	
	if not nearest:
		return 0
	
	var dist: float = SpatialUtil.get_distance_between_entities(entity, nearest)
	return remap(dist, radius, 0, 0, 1)


func _find_nearest_threat(entity: Entity) -> Entity:
	var space_state: PhysicsDirectSpaceState2D = entity.get_world_2d().direct_space_state
	var nearby: Array[Entity] = []
	match detection_type:
		0:
			nearby = SpatialUtil.get_entities_in_radius(space_state, entity.global_position, radius, physics_layer)
		1:
			var facing: FacingComponent = entity.get_component(FacingComponent)
			nearby = SpatialUtil.get_entities_in_cone(space_state, entity.global_position, facing.get_direction(), radius, cone_angle, physics_layer)
	if nearby.is_empty():
		return null
	
	var candidates: Array[Entity] = []
	for e in nearby:
		# don't count entity of the same species
		if (e.basename == entity.basename and not count_same_species) and threat_exceptions["same_species"] == true:
			continue
		# don't count entities that weigh less
		if (e.mass < entity.mass) and threat_exceptions["weigh_less"] == true:
			continue
		# don't count passive entities
		if (e.archetype.behavior_class == CreatureArchetype.BehaviorClass.PASSIVE) and threat_exceptions["isnt_passive"] == true:
			continue
		# don't count nonliving entities
		if (not e.has_component(Brain)) and threat_exceptions["has_brain"] == true:
			continue
		# don't count entities that aren't in line of sight
		if (not SpatialUtil.has_los_of(entity, e)) and threat_exceptions["has_LOS"] == true:
			continue
		candidates.append(e)
	
	if candidates.is_empty():
		return null
	
	return SpatialUtil.get_nearest_entity_in_array(entity.global_position, candidates)
