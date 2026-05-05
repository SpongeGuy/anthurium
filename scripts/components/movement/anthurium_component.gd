extends Component
class_name AnthuriumComponent

# ---------------------------------
# registers the entity to the anthurium brain!
# ---------------------------------

var basename: StringName
@export var health_component: HealthComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if health_component:
		health_component.taken_damage.connect(_on_hit)

func _on_registered() -> void:
	AnthuriumBrain.add_active_part(entity)
	
func _exit_tree() -> void:
	AnthuriumBrain.remove_active_part(entity)

func _on_hit(amount: float, source: Entity) -> void:
	AnthuriumBrain.just_took_damage.emit(amount, source)
	
