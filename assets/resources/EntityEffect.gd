extends Resource
class_name EntityEffect

var visibility: VisibilityComponent

func execute(entity: Entity) -> void:
	if visibility:
		if visibility.is_visible():
			_execute(entity)
			return
		else:
			return
	
	# find visibility component if not visibility
	visibility = entity.get_component(VisibilityComponent)
	if not visibility or (visibility and visibility.is_visible()):
		_execute(entity)
		return

## overload this
func _execute(entity: Entity) -> void:
	pass
