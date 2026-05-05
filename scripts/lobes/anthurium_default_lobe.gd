extends Lobe
class_name AnthuriumDefaultLobe

# ------------------------------------------------------------------------------------------
# a component for a Brain component.
# holds references to other components and reacts to their signals
# holds vital information in memory
# when this information is changed, emit signal changed
# this signal will be transmitted to the brain which will then evaluate all memory to decide to change states
# ------------------------------------------------------------------------------------------

var priority: float = 0.0
@export var state: BehaviorState

func _on_registered() -> void: 
	pass # to be overridden

# returns [priority, BehaviorState]
# priority is a float value from 0.0 to 1.0
# BehaviorState is a BehaviorState referenced by the node (exists on the entity's tree)
func evaluate() -> Array:
	var nutrition_factor: float = 1.0 - (AnthuriumBrain.nutrition_points - 0.0) / (AnthuriumBrain.max_nutrition_points - 0.0)
	
	var core_count: int = AnthuriumBrain.get_count_of_part(&"anthurium_core")
	var parts_factor: float = clampf((AnthuriumBrain.active_anthurium_parts.size() / core_count) / 100.0, 0.0, 1.0)
	parts_factor = pow(parts_factor, 0.5)
	print("P: ", parts_factor)
	
	priority = (nutrition_factor * 0.5) + (parts_factor * 0.5)
	return [priority, state]

# should be used to write stuff to memory
func commit(memory: Memory) -> void:
	pass

