extends Component
class_name IchorComponent

@export var max_ichor: float = 100.0
@export var ichor: float = 100.0
@export var reduction_per_second: float = 0.5

func _process(delta: float) -> void:
	ichor = clampf(ichor - (reduction_per_second * delta), 0.0, max_ichor)

func _on_registered() -> void:
	pass # replace with function body
