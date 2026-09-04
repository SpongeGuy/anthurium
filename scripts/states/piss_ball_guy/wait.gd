extends BehaviorState
class_name WaitState

@export var min_time: float = 0.0
@export var max_time: float = 0.0
@export var facing: FacingComponent
@export var next_state: BehaviorState
@export var enter_effect: EntityEffect

var _timer: float = 0.0

func enter() -> void:
	_timer = randf_range(min_time, max_time)
	if enter_effect:
		enter_effect.execute(state_machine.entity)
	
func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.switch(next_state)
	
func physics_update(delta: float) -> void:
	pass
	
func exit() -> void:
	pass
