extends BehaviorState
class_name PathfindToTargetState

@export var movement: MovementComponent
@export var target_seeker: TargetSeeker
@export var navigation_agent: NavigationAgent2D
@export var input: InputComponent


@export_group("Optional")
@export var animator: SpriteAnimator
@export var facing: FacingComponent

@export_group("States")
@export var target_reached_state: BehaviorState
@export var exit_state: BehaviorState

@export_group("Variables")

@export var timer_length: float = 5.0
var target: Node2D
var target_position: Vector2 = Vector2.INF
var chase_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
@export var wander_radius: float = 250.0

@export var target_reached_threshold: float = 25.0


signal picked_new_path(target_position: Vector2)
signal target_lost()
signal target_reached()
signal interrupted()

func enter() -> void:
	target = _get_target()
	if target:
		target_position = target.global_position
	_pick_new_pathfinding_location()
	
	if navigation_agent:
		navigation_agent.navigation_finished.connect(_on_navigation_finished)
	
	target_lost.connect(_on_target_lost)
	
	if animator:
		animator.load_and_reset_animation("walk")
		
	if target_reached_state:
		target_reached.connect(_on_target_reached)
		
func update(delta: float) -> void:
	if not is_instance_valid(target):
		target_lost.emit()
	
	target = _get_target()
	
	if target:
		target_position = target.global_position
		chase_timer = timer_length
		if owner.global_position.distance_to(target.global_position) < target_reached_threshold:
			target_reached.emit()
	else:
		chase_timer -= delta
	
	if chase_timer <= 0.0:
		target_lost.emit()
		
	
	
	
func physics_update(delta: float) -> void:
	# since we're chasing an object, we have to get a new pathfinding target location every frame
	_pick_new_pathfinding_location()
	
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	wander_direction = (next_path_position - owner.global_position).normalized()
	var steering = wander_direction
	input.set_move_input_direction(steering)
	movement.physics_update(delta, owner)
	
	if facing:
		facing.change_direction(steering)	

		
func _on_target_lost() -> void:
	state_machine.switch(exit_state)

func exit() -> void:
	if navigation_agent:
		navigation_agent.navigation_finished.disconnect(_on_navigation_finished)
		
	target_lost.disconnect(_on_target_lost)
	
	if target_reached_state:
		target_reached.disconnect(_on_target_reached)
		
		
func _pick_new_pathfinding_location() -> void:
	navigation_agent.set_target_position(target_position)
	chase_timer = timer_length
	picked_new_path.emit(target_position)
	
func _on_navigation_finished() -> void:
	interrupted.emit()
	_pick_new_pathfinding_location()

func _on_target_reached() -> void:
	state_machine.switch(target_reached_state)

func _get_target() -> Node2D:
	if target_seeker:
		var t = target_seeker.find_nearest_target(owner.global_position, movement.velocity.normalized())
		return t
	return null
