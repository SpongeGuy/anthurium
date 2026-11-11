extends Resource
class_name LocomotionProfile

## computes and returns this tick's velocity. handler is passed in
## so the profile can read shared context (input, speed) and read/write
## the handler's own per-entity fields. handler is never shared so mutating it
## here is always safe to do
func move(handler: LocomotionHandler, delta: float) -> Vector2:
	return Vector2.ZERO

func handle_step(handler: LocomotionHandler) -> void:
	pass

func _handle_step(handler: LocomotionHandler) -> void:
	handler.unhandled_step = false
	handle_step(handler)
	handler.step.emit()
