extends BehaviorState
class_name SpawnAnthuriumPartThenExit



@export var exit_state: BehaviorState
@export var time_to_spawn: float = 0.0
@export var spawner: AnthuriumGrowthNodeSpawnerComponent
var _timer: float = 0.0

func enter() -> void:
	_timer = time_to_spawn
	spawner.ready_to_spawn_part = true
	
func update(delta: float) -> void:
	if _timer > 0:
		_timer -= delta
	
	if _timer <= 0:
		spawner.spawn_at(state_machine.entity.global_position)
		state_machine.switch(exit_state)
	
func physics_update(delta: float) -> void:
	pass
	
func exit() -> void:
	pass
