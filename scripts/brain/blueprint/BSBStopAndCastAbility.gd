class_name BSBStopAndCastAbility extends BrainStateBlueprint

# provide exported variables to be set in _configure()
@export var cast_timer: float = 2.0
@export var cast_ability: EntityEffect

func _init() -> void:
	# set state_script to the corresponding state script here!
	state_script = StateStopAndCastAbility

# set state's values to the exported values here
func _configure(state: BrainState) -> void:
	state.cast_timer = cast_timer
	state.cast_ability = cast_ability
