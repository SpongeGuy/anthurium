extends Lobe
class_name HungerLobe

# ------------------------------------------------------------------------------------------
# a component for a Brain component.
# holds references to other components and reacts to their signals
# holds vital information in memory
# when this information is changed, emit signal changed
# this signal will be transmitted to the brain which will then evaluate all memory to decide to change states
# ------------------------------------------------------------------------------------------

@export var ichor: IchorComponent
@export var state: BehaviorState
var priority: float = 0.0

func _on_registered() -> void: 
	pass # replace with function body

func evaluate() -> Array: 
	priority = 1 - (ichor.ichor / ichor.max_ichor)
	return [priority, state]

# should be used to write stuff to memory
func commit(memory: Memory) -> void:
	pass
