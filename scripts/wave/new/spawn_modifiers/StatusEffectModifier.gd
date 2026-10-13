class_name StatusEffectModifier extends SpawnModifier
@export var effect: StringName
func apply(request: SpawnRequest) -> void: 
	request.status_effects.append(effect)
