extends Resource
class_name EntityEffect

var visibility: VisibilityComponent
@export var ignore_invisibility: bool = false
@export_range(0.0, 1.0) var percent_chance: float = 1.0

func execute(entity: Entity) -> void:
	if ignore_invisibility:
		_execute(entity)
	if visibility:
		if visibility.is_visible():
			_execute(entity)
			return
	
	# find visibility component if not visibility
	visibility = entity.get_component(VisibilityComponent)
	if not visibility or (visibility and visibility.is_visible()):
		_execute(entity)
		return
		
func _chance_try_execute(entity: Entity) -> void:
	if randf() < percent_chance:
		_execute(entity)

## overload this
func _execute(entity: Entity) -> void:
	pass
