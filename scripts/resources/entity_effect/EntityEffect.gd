extends Resource
class_name EntityEffect

@export var ignore_invisibility: bool = false
@export_range(0.0, 1.0) var percent_chance: float = 1.0


## emitted after this effect has fully resolved for [param entity], including
## any internal awaiting done by [method _execute] (an animation, nested, sequence
## etc). Always fires exactly once per [method execute] call, even when the effect was skipped
##
## IMPORTANT: this resource is very likely shared across many entities. This signal can fire
## concurrently for different entities on the same shared instance. Never write
## `await some_effect.finished` and assume it means "my entity is done".
## always check the [param entity] argument first.
signal finished(entity: Entity)

func execute(entity: Entity) -> void:
	if not _passes_chance():
		finished.emit(entity)
		return
	
	if ignore_invisibility or not _entity_is_invisible(entity):
		await _execute(entity)
	
	finished.emit(entity)
		
func _passes_chance() -> bool:
	return randf() < percent_chance

func _entity_is_invisible(entity: Entity) -> bool:
	if WorldGrid.is_entity_out_of_bounds(entity):
		return true
	var cell: CellData = WorldGrid.get_cell(WorldGrid.world_to_tile(entity.global_position))
	return cell.invisible if cell else false

## override this. if the work is asynchronous (an animation, tween, a nested effect), use
## [code]await[/code] inside it; [method execute] will correctly wait for the whole thing.
func _execute(entity: Entity) -> void:
	pass
