extends Component
class_name EasyTimer

@export var time_limit: float = 5
var time: float = 0.0
var random_delay: float = 0.0
@export var loop: bool = true
@export var chance_to_emit: float = 1.0
@export var randomize_min: float = 0.0
@export var randomize_max: float = 0.0

signal timer_finished

func reset_timer() -> void:
	randomize()
	random_delay = randf_range(randomize_min, randomize_max)
	time = 0.0

func _process(delta: float) -> void:
	time += delta
	if time >= time_limit + random_delay:
		if randf() < chance_to_emit:
			timer_finished.emit()
		if loop:
			reset_timer()
