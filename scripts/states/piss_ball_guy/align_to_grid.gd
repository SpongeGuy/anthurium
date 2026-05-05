extends BehaviorState
class_name AlignToGridState

@export var movement: MovementComponent
@export var input: InputComponent
@export var facing: FacingComponent
@export var sound: SoundPlayer

@export var next_state: BehaviorState

@export var time: float = 1.0
var _timer: float = 0.0
var previous_max_speed: float

func enter() -> void:
	previous_max_speed = movement.max_speed
	movement.max_speed = 100
	_timer = 0
	sound.play_sound()
	
	
func update(delta: float) -> void:
	_timer += delta
	if _timer >= time:
		state_machine.switch(next_state)
	
func physics_update(delta: float) -> void:
	var safe_pos: Vector2 = WorldGrid.tile_to_world(WorldGrid.get_safe_coords(WorldGrid.world_to_tile(state_machine.entity.global_position), CellData.TerrainType.GROUND))
	
	if not state_machine.entity.global_position.is_equal_approx(safe_pos):
		var move_direction: Vector2 = safe_pos - state_machine.entity.global_position
		input.move_input_direction = move_direction
	
	var distance: float = state_machine.entity.global_position.distance_to(safe_pos)
	movement.max_speed = clampf(distance / 32.0, 25, 100.0)
	
func exit() -> void:
	_timer = 0
	movement.max_speed = previous_max_speed
