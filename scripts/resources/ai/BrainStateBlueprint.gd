extends Resource
class_name BrainStateBlueprint

## which BrainState subclass to instantiate. must accept (entity) in _init
@export var state_script: Script

## only used if state_script extends ContainerState
@export var is_container: bool = false
@export var child_states: Array[BrainStateBlueprint] = []
@export var child_names: Array[StringName] = [] # parallel array, see note below
@export var entry_child: StringName = &""

func instantiate(entity: Entity, brain: Brain) -> BrainState:
	var state: BrainState = state_script.new(entity, brain)
	if is_container and state is ContainerState:
		for i in child_states.size():
			state.inner_machine.add_state(child_names[i], child_states[i].instantiate(entity, brain))
		state.entry_state = entry_child
	return state
