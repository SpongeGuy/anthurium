extends Resource
class_name EntityEffect

@export var ignore_invisibility: bool = false
@export_range(0.0, 1.0) var percent_chance: float = 1.0

func execute(entity: Entity) -> void:
	if ignore_invisibility:
		_execute(entity)
	var is_invisible: bool = WorldGrid.get_cell(WorldGrid.world_to_tile(entity.position)).invisible
	if is_invisible == false:
		_execute(entity)
		return
		
func _chance_try_execute(entity: Entity) -> void:
	if randf() < percent_chance:
		_execute(entity)

## overload this
func _execute(entity: Entity) -> void:
	pass
