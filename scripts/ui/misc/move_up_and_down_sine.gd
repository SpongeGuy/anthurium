extends Node2D

@export var position_curve: Curve
var _timer: float = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_timer += delta
	if _timer > 10:
		_timer = 0
	position.y = -position_curve.sample(_timer)
