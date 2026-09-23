extends BrainLobe
class_name LobeHurt

@export var hurt_threshold_ratio: float = 0.5
@export var curve: Curve

func get_priority(entity: Entity) -> float:
	# [---------] max is outside this range
	# where min is 0 and max is hp.max_health * hurt_threshold_ratio remapped to 1
	var hp: HealthComponent = entity.get_component(HealthComponent)
	var current_health: float = hp.health
	var adj_max: float = hp.max_health * hurt_threshold_ratio
	if current_health >= adj_max:
		return 0
	var mapped: float = remap(current_health, 0.0, adj_max, 0.0, 1.0)
	return curve.sample(mapped) if curve else mapped

