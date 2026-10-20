class_name BSBContainer extends BrainStateBlueprint

@export var entry_child: StringName = &""
@export var child_names: Array[StringName] = [] # parallel array, see note below
@export var child_states: Array[BrainStateBlueprint] = []

func _init() -> void:
	state_script = ContainerState

func instantiate(entity: Entity, brain: Brain) -> BrainState:
	var state = super.instantiate(entity, brain)
	for i in child_states.size():
		state.inner_machine.add_state(child_names[i], child_states[i].instantiate(entity, brain))
	state.entry_state = entry_child
	return state

