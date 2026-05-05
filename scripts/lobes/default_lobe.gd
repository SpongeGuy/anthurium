extends Lobe
class_name DefaultLobe

@export var priority: float = 0.01
@export var state: BehaviorState

func evaluate() -> Array: # also to be overridden
	return [priority, state]

# should be used to write stuff to memory
func commit(memory: Memory) -> void:
	pass
