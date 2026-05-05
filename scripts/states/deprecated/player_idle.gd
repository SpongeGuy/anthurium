extends BehaviorState
class_name PlayerIdleState
## states should only include logic which alters data.
## all other functions should be outsourced to other components, such as visual effects or sounds.
@export var move_state: BehaviorState
@export var input: InputComponent
@export var movement: MovementComponent
@export var animator: DirectionalSpriteAnimator

## called once when the state machine does its initial switch to this state
func enter() -> void:
	pass
	
## called every frame while this state is active
func update(delta: float) -> void:
	if animator:
		animator.animation_speed_modifier = 0
	input.set_move_input_direction(Vector2.ZERO)
	
## called every physics frame while this state is active
func physics_update(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("west", "east", "north", "south")
	if abs(direction.length()) > 0.1:
		state_machine.switch(move_state)
		
	
## called once when this state is switched from
func exit() -> void:
	pass

