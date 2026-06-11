extends BehaviorState
class_name GatherEnergyState


@export var time_min: float = 1.0
@export var time_max: float = 2.0
@export var input: InputComponent
@export var facing: FacingComponent
@export var ability_to_use: int = 0
@export var ability_manager: AbilityManager
@export var locomotion: LocomotionHandler
@export var next_state: BehaviorState
@export var voice: VoiceProfile = preload("res://scripts/resources/voices/machine_agree.tres")



var _timer: float = 0.0

func enter() -> void:
	randomize()
	_timer = randf_range(time_min, time_max)
	if not input.player_controlled:
		randomly_change_direction()
		AudioManager.play_voice(voice, state_machine.entity)
		
	locomotion.disabled = true
	ability_manager.abilities[ability_to_use].finished.connect(_change_state)
	
func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		ability_manager.enable(ability_to_use)
		if not input.player_controlled:
			input.press_action(ability_to_use)
			input.release_action(ability_to_use)
			_timer = 1000
	
func physics_update(delta: float) -> void:
	input.move_input_direction = (Vector2.ZERO)

func _change_state() -> void:
	state_machine.switch(next_state)

func exit() -> void:
	input.release_action(ability_to_use)
	ability_manager.disable(ability_to_use)
	locomotion.disabled = false
	ability_manager.abilities[ability_to_use].finished.disconnect(_change_state)


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
