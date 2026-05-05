extends BehaviorState
class_name IdleState

@export var exit_state: BehaviorState
@export var movement: MovementComponent
@export var input: InputComponent
@export_group("Optional")
@export var animator: SpriteAnimator
@export_group("Variables")
@export var idle_duration_min: float = 1.0
@export var idle_duration_max: float = 1.0
var timer: float = 0.0
var idle_duration: float = 1.0

func enter() -> void:
	timer = 0.0
	resolve_idle_duration()
	if animator:
		animator.load_and_reset_animation("idle")
		
func resolve_idle_duration() -> void:
	idle_duration = randf_range(idle_duration_min, idle_duration_max)
	
func update(delta: float) -> void:
	timer += delta
	if timer >= idle_duration:
		state_machine.switch(exit_state)
		
	if input:
		input.set_move_input_direction(Vector2.ZERO)
	
func physics_update(delta: float) -> void:
	movement.physics_update(delta)

	
	
func exit() -> void:
	pass
