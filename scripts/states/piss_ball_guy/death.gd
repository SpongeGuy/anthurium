extends BehaviorState
class_name DeathState

## called once when the state machine does its initial switch to this state
func enter() -> void:
	for child in state_machine.entity.get_children():
		if child is Area2D:
			child.set_deferred("monitorable", false)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	# yeah this is bad but idk man whatever fuck it we ball seriously
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

