extends Resource
class_name BrainStateBlueprint

## which BrainState subclass to instantiate. must accept (entity) in _init
@export var state_script: Script
@export var effects: Dictionary[StringName, EntityEffect] = {}

@export_group("Container")
## only used if state_script extends ContainerState
@export var is_container: bool = false
@export var entry_child: StringName = &""
@export var child_names: Array[StringName] = [] # parallel array, see note below
@export var child_states: Array[BrainStateBlueprint] = []




func instantiate(entity: Entity, brain: Brain) -> BrainState:
	if not state_script:
		Log.error("State script not defined for entity type '%s'!" % entity.basename, true)
	var state: BrainState = state_script.new(entity, brain)
	state.effects = effects.duplicate()
	if is_container and state is ContainerState:
		for i in child_states.size():
			state.inner_machine.add_state(child_names[i], child_states[i].instantiate(entity, brain))
		state.entry_state = entry_child
	return state
