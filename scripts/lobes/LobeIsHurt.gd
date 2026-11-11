extends BrainLobe
class_name LobeIsHurt


func get_priority(entity: Entity) -> float:
	# [---------] max is outside this range
	# where min is 0 and max is hp.max_health * hurt_threshold_ratio remapped to 1
	var hp: HealthComponent = entity.get_component(HealthComponent)
	if hp.health < hp.max_health:
		return 1
	return 0
