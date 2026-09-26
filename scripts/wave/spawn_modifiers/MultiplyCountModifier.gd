class_name MultiplyCountModifier extends SpawnModifier
@export var multiplier: int = 2
func apply(request: SpawnRequest) -> void: request.count *= multiplier
