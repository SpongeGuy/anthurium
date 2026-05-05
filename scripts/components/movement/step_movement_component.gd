extends MovementComponent
class_name StepMovementComponent

@export var step_delay: float = 0.75
var step_timer: float = 0.0
@export var step_power: float = 25
@export var step_factor: float = 20

signal stepping()
signal stepped()

var just_stepped: bool = false
var last_velocity: Vector2 = Vector2.ZERO

func movement_function(delta: float) -> void:
	# lerp velocity to zero always
	last_velocity = velocity
	velocity = velocity.move_toward(Vector2.ZERO, delta * friction)
			
	if input.move_input_direction.length() > 0:
		
		# after a delay, set velocity to a number
		step_timer += delta
		if step_timer >= step_delay:
			stepping.emit()
			just_stepped = true
			step_timer = 0.0
			var target_velocity = input.move_input_direction * max_speed * step_power
			velocity = velocity.move_toward(target_velocity, acceleration * delta * step_factor)
			
	else:
		step_timer = 0.0 - randf_range(0, 1)
		
	if just_stepped and is_zero_approx(step_timer):
		stepped.emit()
		just_stepped = false
		

	
