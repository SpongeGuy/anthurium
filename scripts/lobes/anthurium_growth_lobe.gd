extends Lobe
class_name AnthuriumGrowthLobe

var pmax: float
var pmin: float
@export var state: BehaviorState

func _on_registered() -> void: 
	pass # to be overridden

func evaluate() -> Array: # also to be overridden
	pmax = AnthuriumBrain.max_nutrition_points / 3
	pmin = AnthuriumBrain.max_nutrition_points / 25
	
	var nutrition_factor: float = clamp((AnthuriumBrain.nutrition_points - pmin) / (pmax - pmin), 0.0, 1.0)
	var priority: float = (nutrition_factor * 1.0)
	
	return [priority, state]

# should be used to write stuff to memory
func commit(memory: Memory) -> void:
	pass
