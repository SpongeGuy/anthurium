extends BehaviorState
class_name WanderState

@export var movement: MovementComponent
@export var input: InputComponent
@export var wall_avoidance: WallAvoidance
@export var target_seeker: TargetSeeker
@export var chase_state: BehaviorState

var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO

func enter() -> void:
	_pick_new_wander_direction()
	if target_seeker:
		target_seeker.target_found.connect(_on_target_found)
		
func update(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0:
		_pick_new_wander_direction()
		
	var steering = wander_direction
	
	if wall_avoidance:
		var avoidance = wall_avoidance.get_avoidance_vector(owner.global_position)
		steering += avoidance
		
	if target_seeker:
		var target = target_seeker.find_nearest_target(
			owner.global_position,
			movement.velocity.normalized()
		)
		
	input.set_move_input_direction(steering)
	
	
func exit() -> void:
	if target_seeker:
		target_seeker.target_found.disconnect(_on_target_found)
		
func _pick_new_wander_direction() -> void:
	
	wander_direction = Vector2.RIGHT.rotated(randf() * TAU)
	wander_timer = randf_range(1.5, 4.0)
	
func _on_target_found(target: Node2D) -> void:
	if chase_state:
		state_machine.transition(chase_state)
