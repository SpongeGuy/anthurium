extends Component
class_name ManualStateSwitcher

@export var state_machine: StateMachine
@export var state: BehaviorState

func switch() -> void:
	state_machine.switch(state)

func object_switch(object: Node2D) -> void:
	if state_machine.current_state != state:
		state_machine.data.object = object
		switch()
