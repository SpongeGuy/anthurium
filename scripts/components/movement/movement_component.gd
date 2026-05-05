extends Component
class_name MovementComponent

@export var disabled: bool = false

@export var max_speed: float = 100.0
@export var acceleration: float = 500.0
@export var friction: float = 800.0 # how fast it stopps
@export var rotation_speed: float = 10.0 # for smooth turning
@export var knockback: KnockbackComponent
@export var world_interface: WorldInterface
@export var input: InputComponent

@export var do_movement_function: bool = true
@export var apply_acceleration: bool = true
@export var apply_friction: bool = true

@export var input_disabled: bool = false

var velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if disabled:
		return
	physics_update(delta)
	
func physics_update(delta: float) -> void:
	if input_disabled:
		input.move_input_direction = Vector2.ZERO
	if input and not input_disabled:
		movement_function(delta)
	_handle_cell_terrain(delta) # cell stuff, ground effects
	_apply_knockback()
	
	entity.velocity = velocity
	entity.move_and_slide()
	velocity = entity.velocity
	
	_apply_friction(delta)
	
	_handle_passive_collisions()
	_handle_bounce_collisions() # knockback purposes
	
	
## applies custom logic to velocity and applies velocity to the body according to conditions
func movement_function(delta: float) -> void:	
	var final_max_speed: float = max_speed
	
	if world_interface:
		final_max_speed *= world_interface.cell_movement_modifier()
	
	
	if input.move_input_direction.length() > 0:
		var target_velocity = input.move_input_direction * final_max_speed
		if apply_acceleration:
			velocity = velocity.move_toward(target_velocity, acceleration * delta)
		else:
			velocity = target_velocity


func _apply_friction(delta: float) -> void:
	if not apply_friction:
		return
	if not input or input.move_input_direction.is_zero_approx():
		velocity = velocity.move_toward(Vector2.ZERO, delta * friction)
		
	
	


func _handle_cell_terrain(delta: float) -> void:
	if not world_interface: 
		return

func _handle_passive_collisions() -> void:
	var restitution: float = 1.2
	if entity is not CharacterBody2D:
		return
	
	
	for i in entity.get_slide_collision_count():
		var col: KinematicCollision2D = entity.get_slide_collision(i)
		var collider_velocity = col.get_collider_velocity()
		var normal: Vector2 = col.get_normal()
		
		var relative_velocity: Vector2 = collider_velocity - velocity
		var push_amount: float = relative_velocity.dot(normal)

		if push_amount > 0:
			velocity += normal * push_amount * restitution

	
	
# -------------------------
# knockback
# -------------------------	

func _apply_knockback() -> void:
	if knockback:
		velocity += knockback.knockback_velocity

func _handle_bounce_collisions() -> void:
	if not knockback:
		return
	if entity is not CharacterBody2D:
		return
	if knockback.knockback_velocity.length() > knockback.min_bounce_speed:
		for i in entity.get_slide_collision_count():
			var col: KinematicCollision2D = entity.get_slide_collision(i)
			knockback.knockback_velocity = knockback.knockback_velocity.bounce(col.get_normal()) * knockback.bounce_factor
