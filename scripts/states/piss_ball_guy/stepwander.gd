extends BehaviorState
class_name WandererState

@export var proximity: ProximityDetector
@export var facing: FacingComponent
@export var input: InputComponent
@export var movement: StepMovementComponent
@export var player: SoundPlayer
@export var obstruction: ObstructionDetector

@export var exit_state: BehaviorState

var target: Entity
var distance_traveled: float = 0.0

var patience: float = 0.0
var patience_limit: float = 0.75

var ok_to_turn: bool = false

func _on_stepping() -> void:
	player.play_sound()

func _on_stepped() -> void:
	
	ok_to_turn = true
	decide_to_move()

func enter() -> void:
	facing.change_direction(Vector2(1, 0))
	movement.stepped.connect(_on_stepped)
	movement.stepping.connect(_on_stepping)
	
func update(delta: float) -> void:
	pass
	
func physics_update(delta: float) -> void:
	# attempt to turn direction
		# random chance to turn
	
	if ok_to_turn:
		randomly_change_direction()
		
	
	# attempt to move
		# do not move into an obstruction
		# if there is an obstruction in front, either change state or continue (and attempt to turn direction again)
	if not obstruction.is_facing_obstruction:
		distance_traveled += state_machine.entity.velocity.length()
		input.move_input_direction = facing.get_direction()
	else:
		input.move_input_direction = Vector2.ZERO
		ok_to_turn = true
	
func exit() -> void:
	movement.stepped.disconnect(_on_stepped)
	movement.stepping.disconnect(_on_stepping)



func avoid_changing_dir_into_colliders() -> Vector2:
	return Vector2.ZERO

func randomly_change_direction() -> void:
	if randf() < 0.5:
		return
		
	var dirs: Array = [
		Vector2(1, 0),
		Vector2(0, 1),
		Vector2(-1, 0),
		Vector2(0, -1)
	]
	var is_wall_in_front: bool = true
	var dir: Vector2
	
	for i in range(25):
		if is_wall_in_front:
			dir = dirs.pick_random()
			var tile_pos_and_facing: CellData = WorldGrid.safe_get_cell(WorldGrid.world_to_tile(state_machine.entity.global_position) + Vector2i(dir.round()))
			if tile_pos_and_facing:
				is_wall_in_front = tile_pos_and_facing.terrain == CellData.TerrainType.WALL
		
	facing.change_direction(dir)
	ok_to_turn = false
	
	




func decide_to_move() -> void:
	if randf() < 0.1:
		state_machine.switch(exit_state)
