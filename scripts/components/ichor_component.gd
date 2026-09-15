extends Component
class_name IchorComponent

@export var max_ichor: float = 100.0
@export var ichor: float = 100.0
@export var reduction_per_second: float = 0.1
@export var max_reduction_per_second: float = 0.05
@export_category("Diffusion")
@export var diffusion_rate: float = 0.3
@export var reserved_ichor: float = 0.0
@export_category("Senescence")
## Maps age/lifespan fraction [0, 1] to a max_ichor multiplier. Keep this
## near 1.0 for most of the curve and taper toward the end; vitality
## holding steady until close to natural expiry, not a straight line down.
@export var senescence_curve: Curve = preload("uid://dal7rl6eaqvss")
## max_ichor never drops below this fraction of base_max_ichor, however
## close to lifespan the entity gets.
@export_range(0, 1) var senescence_floor: float = 0.0

var base_max_ichor: float
@export var lifespan: LifespanComponent

signal ichor_changed(value: float, max_value: float)

func _on_registered() -> void:
	base_max_ichor = max_ichor


func _process(delta: float) -> void:
	if lifespan:
		var age_fraction: float = clampf(lifespan.age / lifespan.lifespan, 0.0, 1.0)
		var vitality: float = senescence_curve.sample(age_fraction) if senescence_curve else (1.0 - age_fraction)
		max_ichor = base_max_ichor * lerpf(senescence_floor, 1.0, vitality)
		if ichor > max_ichor:
			set_ichor(ichor)
	subtract_ichor(reduction_per_second * delta)
	
	
func reset_stats(value: float, max_value: float) -> void:
	base_max_ichor = max_value
	max_ichor = max_value
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
