extends Component
class_name SaturationComponent

@export var max_saturation: float = 100.0
@export var saturation: float = 100.0
@export var reduction_per_second: float = 0.5

func _process(delta: float) -> void:
	saturation = clampf(saturation - (reduction_per_second * delta), 0.0, max_saturation)

func _on_registered() -> void:
	pass # replace with function body


