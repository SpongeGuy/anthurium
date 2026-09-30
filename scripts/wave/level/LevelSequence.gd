class_name LevelSequence extends Resource
@export var scripted_levels: Array[LevelDefinition] = []
@export var generator: LevelGenerator
@export var endless: bool = false

func get_level(level_value: int, escalation: int) -> LevelDefinition:
	if level_value < scripted_levels.size():
		return scripted_levels[level_value]
	if generator and endless:
		return generator.generate_level(level_value, escalation)
	return null
	
func is_exhausted(level_value: int, escalation: int) -> bool:
	if endless:
		return false
	return get_level(level_value, escalation) == null
