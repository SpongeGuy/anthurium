extends Component
class_name BloomThresholdComponent

@export var threshold: float = 100.0
@export var bloom_potential: BloomPotentialComponent

func _ready() -> void:
	bloom_potential.potential_changed.connect(_on_potential_changed)
	
func _on_potential_changed(value: float) -> void:
	if value >= threshold:
		AnthuriumInterface.trigger_bloom(entity)
		bloom_potential.clear()
