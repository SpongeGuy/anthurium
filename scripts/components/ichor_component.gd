extends Component
class_name IchorComponent

@export var max_ichor: float = 100.0
@export var ichor: float = 100.0
@export var reduction_per_second: float = 0.1
@export_group("Diffusion")
@export var diffusion_rate: float = 0.3
@export var reserved_ichor: float = 0.0

signal ichor_changed(value: float, max_value: float)

func _process(delta: float) -> void:
	subtract_ichor(reduction_per_second * delta)
	
func reset_stats(value: float, max: float) -> void:
	max_ichor = max
	set_ichor(value)
	
func set_ichor(value: float) -> void:
	ichor = clampf(value, 0.0, max_ichor)
	ichor_changed.emit(ichor, max_ichor)
	
func add_ichor(amount: float) -> void:
	ichor = clampf(ichor + (amount), 0.0, max_ichor)
	ichor_changed.emit(ichor, max_ichor)
	
func subtract_ichor(amount: float) -> void:
	ichor = clampf(ichor - (amount), 0.0, max_ichor)
	ichor_changed.emit(ichor, max_ichor)

func take_ichor(amount: float) -> float:
	var available: float = maxf(0.0, ichor - reserved_ichor)
	var actual: float = minf(amount, available)
	subtract_ichor(actual)
	return actual
	
func try_spend(amount: float) -> bool:
	if ichor < amount:
		return false
	subtract_ichor(amount)
	return true

func _on_registered() -> void:
	pass # replace with function body
