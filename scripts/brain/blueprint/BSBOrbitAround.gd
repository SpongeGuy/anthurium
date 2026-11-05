class_name BSBOrbitAround
extends BrainStateBlueprint

enum Mode{ TARGET, MAP_CENTER }

@export var mode: Mode = Mode.TARGET
@export var orbit_speed: float = 1.5
@export var orbit_speed_range: float = 0

@export_group("Target Mode")
@export var radius: float = 25
@export var radius_range: float = 0

@export_group("Map Center Mode")
@export_range(0.05, 1.0, 0.01) var screen_fill: float = 0.6
@export_range(0.0, 0.5, 0.01) var screen_fill_range: float = 0.0
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
	match mode:
		Mode.TARGET:
			state.radius = radius + rng.randf_range(-radius_range, radius_range)
		Mode.MAP_CENTER:
			state.screen_fill = clampf(screen_fill + rng.randf_range(-screen_fill_range, screen_fill_range), 0.05, 1.0)

