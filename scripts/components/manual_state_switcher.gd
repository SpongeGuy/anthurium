extends Component
class_name ManualStateSwitcher

@export var state_machine: StateMachine
@export var state: BehaviorState

func switch() -> void:
	state_machine.switch(state)

func target_switch(source: Entity, target: Entity) -> void:
	state_machine.switch(state)
