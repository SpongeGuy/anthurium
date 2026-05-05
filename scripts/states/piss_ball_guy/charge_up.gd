extends BehaviorState
class_name GatherEnergyState


@export var time_min: float = 1.0
@export var time_max: float = 2.0
@export var sound: SoundPlayer
@export var input: InputComponent
@export var facing: FacingComponent

@export var next_state: BehaviorState

var _timer: float = 0.0

func enter() -> void:
	randomize()
	_timer = randf_range(time_min, time_max)
	sound.play_sound()
	randomly_change_direction()
	
func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.switch(next_state)
		
	
func physics_update(delta: float) -> void:
	input.move_input_direction = Vector2.ZERO
	
func exit() -> void:
	pass


func randomly_change_direction() -> void:
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
