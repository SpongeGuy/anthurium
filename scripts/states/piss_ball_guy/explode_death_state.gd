extends BehaviorState
class_name ExplodeDeathState

@export var hurtbox: Hurtbox

## called once when the state machine does its initial switch to this state
func enter() -> void:
	hurtbox.activate(0, 1)
	var cell: CellData = CellData.new()
	cell.terrain = CellData.TerrainType.GROUND
	cell.skin = 1
	WorldGrid.set_circle(WorldGrid.world_to_tile(state_machine.entity.global_position), 3, cell)
	for child in state_machine.entity.get_children():
		if child is Area2D:
			child.monitorable = false
			
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	owner.queue_free()
	
## called every frame while this state is active
func update(delta: float) -> void:
	pass
	
## called every physics frame while this state is active
func physics_update(delta: float) -> void:
	pass
	
## called once when this state is switched from
func exit() -> void:
	pass
