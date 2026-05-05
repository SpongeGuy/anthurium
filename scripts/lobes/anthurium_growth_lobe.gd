extends Lobe
class_name AnthuriumGrowthLobe

var pmax: float
var pmin: float
@export var state: BehaviorState

func _on_registered() -> void: 
	pass # to be overridden

func evaluate() -> Array: # also to be overridden
	pmax = AnthuriumBrain.max_ichor / 3
	pmin = AnthuriumBrain.max_ichor / 25
	
	var ichor_factor: float = clamp((AnthuriumBrain.ichor - pmin) / (pmax - pmin), 0.0, 1.0)
	var priority: float = (ichor_factor * 1.0)
	
	return [priority, state]

# should be used to write stuff to memory
func commit(memory: Memory) -> void:
	pass
