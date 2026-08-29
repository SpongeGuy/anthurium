extends BehaviorState
class_name AnthuriumStateBeatHeart
## states should only include logic which alters data.
## all other functions should be outsourced to other components, such as visual effects or sounds.

@export var heartbeat_emitter: HeartbeatEmitter
@export var heartbeat_effect: EntityEffect

var _timer: float = 0.0
@export var heartbeat_time: float = 1.0
@export var range: float = 0.1

## called once when the state machine does its initial switch to this state
func enter() -> void:
	pass
	
## called every frame while this state is active
func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		heartbeat_emitter.heartbeat()
		_timer = heartbeat_time
		if heartbeat_effect:
			heartbeat_effect.execute(state_machine.entity)
	
	
	
## called every physics frame while this state is active
func physics_update(delta: float) -> void:
	pass
	
## called once when this state is switched from
func exit() -> void:
	pass

