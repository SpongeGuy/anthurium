extends RefCounted
class_name BrainStateMachine

var states: Dictionary[StringName, BrainState] = {}
var current_name: StringName = &""
var current_state: BrainState = null

signal state_changed(from: StringName, to: StringName)

func add_state(name: StringName, state: BrainState) -> void:
	states[name] = state

func transition_to(name: StringName) -> void:
	if name == current_name or not states.has(name):
		return
	if current_state:
		current_state.exit()
	var old_name: StringName = current_name
	current_name = name
	current_state = states[name]
	current_state.enter()
	state_changed.emit(old_name, name)

func physics_process(delta: float) -> void:
	if not current_state:
		return
	current_state.physics_process(delta)
	var next: StringName = current_state.get_transition()
	if next != &"":
		transition_to(next)
