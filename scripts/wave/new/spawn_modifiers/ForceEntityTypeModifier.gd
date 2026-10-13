class_name ForceEntityTypeModifier extends SpawnModifier
@export var forced_type: StringName
func apply(request: SpawnRequest) -> void: 
	request.entity_type = forced_type
