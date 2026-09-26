
class_name CustomZModifier extends SpawnModifier
@export var z: float
func apply(request: SpawnRequest) -> void: request.z = z
