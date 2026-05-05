extends BehaviorState
class_name PathfindStepWandererState

@export var navigation: NavigationHelper
@export var facing: FacingComponent
@export var input: InputComponent
@export var movement: StepMovementComponent
@export var exit_state: BehaviorState
@export var sound: SoundPlayer

@export var radius: float = 100
@export var chance_to_exit_state: float = 0.05

func _on_stepping() -> void:
	if sound:
		sound.play_sound()

func _on_stepped() -> void:
	decide_to_switch()

func enter() -> void:
	movement.stepped.connect(_on_stepped)
	movement.stepping.connect(_on_stepping)
	
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
	movement.stepped.disconnect(_on_stepped)
	movement.stepping.disconnect(_on_stepping)
	input.move_input_direction = Vector2.ZERO


func decide_to_switch() -> void:
	if randf() < chance_to_exit_state:
		state_machine.switch(exit_state)
		
