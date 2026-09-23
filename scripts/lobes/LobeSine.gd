extends BrainLobe

@export var frequency: float = 50.0
@export var magnitude: float = 0.5

func get_priority(entity: Entity) -> float:
	return sin(entity.age * frequency) * magnitude

