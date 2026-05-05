extends BehaviorState
class_name PathfindWanderState

@export var movement: MovementComponent
@export var navigation_agent: NavigationAgent2D
@export var input: InputComponent

@export_group("Optional")

@export var animator: SpriteAnimator
@export var facing: FacingComponent

@export_group("States")
@export var aggro_state: BehaviorState
@export var idle_state: BehaviorState
@export_group("Variables")

@export var timer_length: float = 5.0
var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
@export var wander_radius: float = 250.0

@export var idle_chance: float = 0.3


signal picked_new_path(target_position: Vector2)
signal interrupted()

func enter() -> void:
	randomize()
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
	var angle: float = randf() * TAU
	var distance = randf() * wander_radius
	var target_position: Vector2 = origin + Vector2(cos(angle), sin(angle)) * distance
	navigation_agent.set_target_position(target_position)
	wander_timer = timer_length
	picked_new_path.emit(target_position)
	
func _on_navigation_finished() -> void:
	interrupted.emit()
	_pick_new_pathfinding_location(owner.position)


func _decide_if_idle() -> void:
	if randf() < idle_chance:
		state_machine.switch(idle_state)


