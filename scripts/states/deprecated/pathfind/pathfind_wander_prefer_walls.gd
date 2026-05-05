extends BehaviorState
class_name PathfindWanderPreferWallsState

@export var movement: MovementComponent
@export var navigation_agent: NavigationAgent2D
@export var input: InputComponent

@export var animator: SpriteAnimator
@export var facing: FacingComponent

@export_group("States")
@export var idle_state: BehaviorState
@export_group("Variables")

@export var timer_length: float = 5.0
var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
@export var wander_radius: float = 250.0


signal picked_new_path(target_position: Vector2)
signal found_target(target: Node2D)
signal interrupted()

func enter() -> void:
	_pick_new_pathfinding_location(owner.position)
		
	if navigation_agent:
		navigation_agent.navigation_finished.connect(_on_navigation_finished)
		
	interrupted.connect(_decide_if_idle)
	
	if animator:
		animator.load_and_reset_animation("walk")
		
func update(delta: float) -> void:
	var old_wander_direction: Vector2 = wander_direction
	wander_timer -= delta
	if wander_timer <= 0:
		interrupted.emit()
		_pick_new_pathfinding_location(owner.position)
	
		
	
func physics_update(delta: float) -> void:
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	wander_direction = (next_path_position - owner.global_position).normalized()
	var steering = wander_direction
		
	input.set_move_input_direction(steering)
	
	movement.physics_update(delta, owner)
	
		
	if facing:
		facing.change_direction(steering)

func exit() -> void:
		
	if navigation_agent:
		navigation_agent.navigation_finished.disconnect(_on_navigation_finished)
		
	interrupted.disconnect(_decide_if_idle)

		
func _pick_new_pathfinding_location(origin: Vector2) -> void:
	var best_position: Vector2 = _sample_best_wander_point(origin)
	navigation_agent.set_target_position(best_position)
	wander_timer = timer_length
	picked_new_path.emit(best_position)


func _sample_best_wander_point(origin: Vector2) -> Vector2:
	var candidates: int = 6
	var best_pos: Vector2 = origin
	var best_score: float = -INF
	
	for i in candidates:
		var angle: float = randf() * TAU
		var distance: float = randf_range(wander_radius * 0.3, wander_radius)
		var candidate: Vector2 = origin + Vector2(cos(angle), sin(angle)) * distance
		
		var score: float = _score_wall_proximity(candidate)
		if score > best_score:
			best_score = score
			best_pos = candidate
			
	return best_pos


func _score_wall_proximity(point: Vector2) -> float:
	var space_state = owner.get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.new()
	params.collision_mask = 1
	var score: float = 0.0
	var check_rays: int = 6
	var check_length: float = 32.0
	
	for i in check_rays:
		var angle: float = (TAU / check_rays) * i
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		params.from = point
		params.to = point + dir * check_length
		var result = space_state.intersect_ray(params)
		if result:
			var proximity: float = 1.0 - (point.distance_to(result.position) / check_length)
			score += proximity
		
	return score


func _on_navigation_finished() -> void:
	interrupted.emit()
	_pick_new_pathfinding_location(owner.position)

func _decide_if_idle() -> void:
	var chance: float = 0.3
	if randf() < 0.3:
		state_machine.switch(idle_state)


