extends BehaviorState
class_name AnthuriumSpawnEntityThenExitState

@export var spawner: EntitySpawner
@export var time_to_spawn: float = 0.0
@export var exit_state: BehaviorState
@export var nutrition_to_lose: float = 100.0
var _timer: float = 0.0

func enter() -> void:
	_timer = time_to_spawn
	
func update(delta: float) -> void:
	if _timer > 0:
		_timer -= delta
	
	if _timer <= 0:
		spawner.spawn_at(state_machine.entity.global_position)
		AnthuriumBrain.nutrition_points -= nutrition_to_lose
		state_machine.switch(exit_state)
	
func physics_update(delta: float) -> void:
	pass
	
func exit() -> void:
	pass
