extends RefCounted
class_name BrainState

## Base class for any state; whether a top-level goal (SeekFood) or a leaf
## behavior inside one (Wander). Container states override _get_transition()
## to drive their own internal StateMachine

var entity: Entity
var brain: Brain
var effects: Dictionary[StringName, EntityEffect] = {}

func _init(e: Entity, b: Brain) -> void:
	entity = e
	brain = b

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

## Plays the effect registered under [param key], if one was assigned via blueprint.
func play_effect(key: StringName) -> void:
	if effects.has(key):
		effects[key].execute(entity)
