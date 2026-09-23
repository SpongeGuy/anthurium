extends BrainLobe
class_name LobeHurt

@export var hurt_threshold_ratio: float = 0.5
@export var curve: Curve

func get_priority(entity: Entity) -> float:
	var hp: HealthComponent = entity.get_component(HealthComponent)
	return 0

