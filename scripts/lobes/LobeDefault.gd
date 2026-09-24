extends BrainLobe
class_name LobeDefault

@export var priority: float = 1.0

func get_priority(entity: Entity) -> float:
	return priority

# lobe should keep track of the last time it was active
# every time it was active and then deactivated, then its priority should be randomized somehow?
