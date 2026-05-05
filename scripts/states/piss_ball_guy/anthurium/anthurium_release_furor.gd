extends BehaviorState
class_name AnthuriumReleaseFuror
## states should only include logic which alters data.
## all other functions should be outsourced to other components, such as visual effects or sounds.

@export var radius: float = 100.0
var origin: Vector2
@export var spawn_names: Array[StringName] = [
	&"anthurium_spine",
	&"anthurium_thorn",
]
@export var next_state: BehaviorState

## called once when the state machine does its initial switch to this state
func enter() -> void:
	origin = state_machine.entity.global_position
	
## called every frame while this state is active
func update(delta: float) -> void:
	var angle: float = randf() * TAU
	var distance = randf() * radius
	var target_position: Vector2 = origin + Vector2(cos(angle), sin(angle)) * distance
	target_position = WorldGrid.get_safe_world_pos(target_position, CellData.TerrainType.GROUND)
	EntityManager.spawn_safely(spawn_names.pick_random(), target_position)
	AnthuriumBrain.nutrition_points -= 50
	AnthuriumBrain.furor -= 0.8
	state_machine.switch(next_state)
	
## called every physics frame while this state is active
func physics_update(delta: float) -> void:
	pass
	
## called once when this state is switched from
func exit() -> void:
	pass

