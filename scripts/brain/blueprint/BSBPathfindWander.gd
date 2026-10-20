class_name BSBPathfindWander extends BrainStateBlueprint

enum Mode{ DEFAULT, OCCASIONALLY_EFFECT, SEEKING_FOOD, SWITCH_WHEN_HURT, SWITCH_AFTER_TIMER }

# provide exported variables to be set in _configure()
@export var mode: Mode = Mode.DEFAULT
@export var min_wander_radius: float = 25
@export var max_wander_radius: float = 100

@export var timer_duration: float = 1

func _init() -> void:
	# set state_script to the corresponding state script here!
	match mode:
		Mode.DEFAULT:
			state_script = StatePathfindWander
		Mode.OCCASIONALLY_EFFECT:
			state_script = StatePathfindWanderOccasionallyEffect
		Mode.SEEKING_FOOD:
			state_script = StatePathfindWanderSeekingFood
		Mode.SWITCH_WHEN_HURT:
			state_script = StatePathfindWanderUntilHurt
		Mode.SWITCH_AFTER_TIMER:
			state_script = StatePathfindWanderThenSwitch

# set state's values to the exported values here
func _configure(state: BrainState) -> void:
	state.min_wander_radius = min_wander_radius
	state.max_wander_radius = max_wander_radius
	match mode:
		Mode.OCCASIONALLY_EFFECT:
			state.timer_base_length = timer_duration
		Mode.SEEKING_FOOD:
			state.search_timer_duration = timer_duration
		Mode.SWITCH_AFTER_TIMER:
			state.timer_base_length = timer_duration
	
