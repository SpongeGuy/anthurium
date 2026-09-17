extends _BASE_

## computes and returns this tick's velocity. handler is passed in
## so the profile can read shared context (input, speed) and read/write
## the handler's own per-entity fields. handler is never shared so mutating it
## here is always safe to do.
## velocity = direction * speed!
func move(handler: LocomotionHandler, delta: float) -> Vector2:
	return Vector2.ZERO
