extends Lobe
class_name AnthuriumReactToDamage

# ------------------------------------------------------------------------------------------
# a component for a Brain component.
# holds references to other components and reacts to their signals
# holds vital information in memory
# when this information is changed, emit signal changed
# this signal will be transmitted to the brain which will then evaluate all memory to decide to change states
# ------------------------------------------------------------------------------------------

@export var state: BehaviorState
var target: Entity
@export var health: HealthComponent


func _on_registered() -> void: 
	AnthuriumBrain.just_took_damage.connect(_just_took_damage)

func evaluate() -> Array: 
	var furor_factor: float = (AnthuriumBrain.furor) * 2
	var nutrition_factor: float = AnthuriumBrain.nutrition_points / AnthuriumBrain.max_nutrition_points
	nutrition_factor = pow(nutrition_factor, 2)
	var priority: float = (furor_factor * (nutrition_factor / 0.5))
	return [priority, state] # replace with function body

# should be used to write stuff to memory
func commit(memory: Memory) -> void:
	memory.set_value(Memory.Key.TARGET, target)

func _just_took_damage(damage_amount: float, source: Node2D) -> void:
	AnthuriumBrain.furor += damage_amount * (1 -(health.health / health.max_health))
	target = source if source is Entity else null
	changed.emit()
