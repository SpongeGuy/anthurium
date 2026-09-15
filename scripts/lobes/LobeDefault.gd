extends BrainLobe
class_name LobeDefault

@export var priority: float = 1.0

func get_priority(entity: Entity) -> float:
	return priority
