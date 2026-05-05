extends BehaviorState
class_name PathfindWandererState

@export var navigation: NavigationHelper
@export var facing: FacingComponent
@export var input: InputComponent
@export var movement: MovementComponent
@export var sound: SoundPlayer
@export var animator: SpriteAnimator

@export var radius: float = 100

func enter() -> void:
	if animator:
		animator.load_and_reset_animation("wander")
	
func update(delta: float) -> void:
	pass
	
func physics_update(delta: float) -> void:
	# get next nav point
		# if no next nav point, then create a new navigation goal
	if not navigation.is_navigating():
		navigation.set_new_pathfinding_location_relative(state_machine.entity.global_position, radius)
	
	var next_point: Vector2 = navigation.get_next_path_direction()
	facing.change_direction(next_point)
	input.move_input_direction = facing.get_direction()
	# turn towards nav point
	# move continuously towards facing direction
	
func exit() -> void:
	pass
		
