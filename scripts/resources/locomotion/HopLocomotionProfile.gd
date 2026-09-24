extends LocomotionProfile
class_name HopLocomotionProfile

## computes and returns this tick's velocity. handler is passed in
## so the profile can read shared context (input, speed) and read/write
## the handler's own per-entity fields. handler is never shared so mutating it
## here is always safe to do.
## velocity = direction * speed!

@export var jump_velocity: float = 120.0
@export var slowdown_factor: float = 1.0

func move(handler: LocomotionHandler, delta: float) -> Vector2:
	if handler.entity.is_on_ground():
		return Vector2.ZERO
	return handler.locked_direction * handler.speed

func handle_step(handler: LocomotionHandler) -> void:
	handler.locked_direction = handler.input.move_input_direction
	handler.entity.jump(jump_velocity)
	handler.speed = handler.max_speed
