extends BehaviorState
class_name DungeoncubeChargeState

@export var movement: MovementComponent
@export var input: InputComponent
@export var facing: FacingComponent
@export var hurtbox: Hurtbox
@export var obstruction: ObstructionDetector
@export var sound: SoundPlayer

@export var next_state: BehaviorState

func enter() -> void:
	movement.max_speed = 500
	input.move_input_direction = facing.get_direction()
	hurtbox.set_active(true)
	sound.play_sound()
	
	
func update(delta: float) -> void:
	if obstruction.is_facing_obstruction:
		state_machine.switch(next_state)
	
func physics_update(delta: float) -> void:
	pass
	
func exit() -> void:
	hurtbox.set_active(false)



