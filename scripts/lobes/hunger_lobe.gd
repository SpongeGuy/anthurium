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

@export var hungry_threshold_ratio: float = 0.3
@export var satiated_threshold_ratio: float = 0.9
var priority: float = 0.0

var _hungry: bool = false

func _on_registered() -> void: 
	pass # replace with function body

func evaluate() -> Array: 
	var hunger_ratio: float = ichor.ichor / ichor.max_ichor
	if hunger_ratio <= hungry_threshold_ratio:
		_hungry = true
	elif hunger_ratio >= satiated_threshold_ratio:
		_hungry = false
	
	var hunger_bonus: float = 0.0
	hunger_bonus = 0.5 if _hungry else 0.0
	priority = 1 - ((hunger_ratio *0.75))  + (hunger_bonus)
	return [priority, state]

# should be used to write stuff to memory
func commit(memory: Memory) -> void:
	pass
