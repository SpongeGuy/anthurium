extends BehaviorState
class_name StandStillAndUseAbilityState

@export var exit_state: BehaviorState
@export var ability_manager: AbilityManager
@export var ability_id: int = 0
@export var input: InputComponent
@export var target_seeker: TargetSeeker
@export_group("Optional")

@export var facing: FacingComponent
@export var animator: SpriteAnimator

@export_group("Variables")
@export var timer_length: float = 3.0

## radius the target has to be in to continue doing ability
@export var attack_radius: float = 16.0

@export var chance_to_give_up: float = 0.0

var hit_time: float = 0.0
var hit_target: Node2D

signal interrupted()

func enter() -> void:
	randomize()
	hit_target = target_seeker.current_target
		
	interrupted.connect(_on_interrupted)
	hit_time = 0.0
	
	if animator:
		animator.load_and_reset_animation("prepping")
		
	if ability_manager:
		ability_manager.get_ability_from_id(ability_id).finished.connect(_on_ability_finished)
	
func update(delta: float) -> void:
	if not is_instance_valid(hit_target):
		interrupted.emit()
		return
	
	if hit_target.global_position.distance_to(owner.global_position) > attack_radius:
		
		interrupted.emit()
	
	hit_time -= delta
	if hit_time <= 0.0:
		if facing:
			facing.change_direction(hit_target.global_position - owner.global_position)
		if animator:
			animator.load_and_reset_animation("attack")
		input.press_action(ability_id)
		input.release_action(ability_id)
		if randf() < chance_to_give_up:
			interrupted.emit()
		
		hit_time = timer_length + randf_range(-0.5, 0.5)
	
	
func physics_update(delta: float) -> void:
	if facing and hit_target:
		facing.change_direction((hit_target.global_position - owner.global_position).normalized())
		
	input.set_move_input_direction(Vector2.ZERO)
	
func exit() -> void:
	interrupted.disconnect(_on_interrupted)
	
	if ability_manager:
		ability_manager.get_ability_from_id(ability_id).finished.disconnect(_on_ability_finished)
	

func _on_ability_finished() -> void:
	if animator:
		animator.load_and_reset_animation("prepping")
	if randf() < chance_to_give_up:
		state_machine.switch(exit_state)

func _on_interrupted() -> void:
	state_machine.switch(exit_state)
