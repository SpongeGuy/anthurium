class_name BSBOrbitAround
extends BrainStateBlueprint

enum Mode{ TARGET, MAP_CENTER }

@export var mode: Mode = Mode.TARGET
@export var radius: float = 25
@export var radius_range: float = 0
@export var orbit_speed: float = 1.5
@export var orbit_speed_range: float = 0
var rng: RandomNumberGenerator

func instantiate(entity: Entity, brain: Brain) -> BrainState:
	rng = RunRng.get_stream("entity")
	match mode:
		Mode.TARGET:
			state_script = StateOrbitAroundTarget
		Mode.MAP_CENTER:
			state_script = StateOrbitAroundMapCenter
	return super(entity, brain)

func _configure(state: BrainState) -> void:
	state.orbit_speed = orbit_speed + rng.randf_range(-orbit_speed_range, orbit_speed_range)
	state.radius = radius + rng.randf_range(-radius_range, radius_range)
