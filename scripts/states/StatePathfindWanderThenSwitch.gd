extends BrainState

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	pass

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	pass

## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	return &""

