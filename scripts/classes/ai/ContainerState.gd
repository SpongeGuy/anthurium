extends BrainState
class_name ContainerState

var inner_machine: BrainStateMachine = BrainStateMachine.new()
var entry_state: StringName

func enter() -> void:
	inner_machine.transition_to(entry_state)

func exit() -> void:
	if inner_machine.current_state:
		inner_machine.current_state.exit()
		inner_machine.current_state = null
		inner_machine.current_name = &""

func physics_process(delta: float) -> void:
	inner_machine.physics_process(delta)
