extends Resource
class_name BrainLobe

@export var state_name: StringName
@export var blueprint: BrainStateBlueprint

func _on_registered(entity: Entity) -> void:
	pass

func get_priority(entity: Entity) -> float:
	return 0.0

