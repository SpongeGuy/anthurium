extends Component
class_name IchorComponent

@export var max_ichor: float = 100.0
@export var ichor: float = 100.0
@export var reduction_per_second: float = 0.1
@export var starve_damage: float = 0.5

signal ichor_changed(value: float, max_value: float)

func _process(delta: float) -> void:
	subtract_ichor(reduction_per_second * delta)
	
func add_ichor(amount: float) -> void:
	ichor = clampf(ichor - (amount), 0.0, max_ichor)
	ichor_changed.emit(ichor, max_ichor)
	
func subtract_ichor(amount: float) -> void:
	ichor = clampf(ichor - (amount), 0.0, max_ichor)
	ichor_changed.emit(ichor, max_ichor)


func _on_registered() -> void:
	pass # replace with function body
