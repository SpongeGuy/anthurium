extends BehaviorState
class_name SpawnEntityThenExitState

@export var spawner: EntitySpawner
@export var time_to_spawn: float = 0.0
@export var exit_state: BehaviorState
@export var enter_effect: EntityEffect
@export var update_effect: EntityEffect
var _timer: float = 0.0

func enter() -> void:
	_timer = time_to_spawn
	if enter_effect:
		enter_effect.execute(state_machine.entity)
	
func update(delta: float) -> void:
	if update_effect:
		update_effect.execute(state_machine.entity)
	if _timer > 0:
		_timer -= delta
	if _timer <= 0:
		spawner.spawn_at(state_machine.entity.global_position)
		state_machine.switch(exit_state)
	
func physics_update(delta: float) -> void:
	pass
	
func exit() -> void:
	pass
