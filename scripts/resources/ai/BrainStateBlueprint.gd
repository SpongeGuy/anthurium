extends Resource
class_name BrainStateBlueprint

## which BrainState subclass to instantiate. must accept (entity) in _init
var state_script: Script
@export var effects: Dictionary[StringName, EntityEffect] = {}

@export_group("Container")
## only used if state_script extends ContainerState





func instantiate(entity: Entity, brain: Brain) -> BrainState:
	if not state_script:
		Log.error("State script not defined for entity type '%s'!" % entity.basename, true)
	var state: BrainState = state_script.new(entity, brain)
	state.effects = effects.duplicate()
	_configure(state)
	return state

func _configure(_state: BrainState) -> void:
	pass
