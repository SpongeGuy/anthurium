class_name TimeCompletionStrategy
extends CompletionStrategy

var _remaining: float

func _init(duration: float) -> void:
	_remaining = duration

func tick(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		_complete()
