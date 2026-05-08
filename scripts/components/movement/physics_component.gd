extends Component
class_name PhysicsComponent

@export var disabled: bool = false

@export var friction: float = 800.0 # how fast it stopps
@export var knockback: KnockbackComponent
@export var world_interface: WorldInterface
@export var locomotion: LocomotionHandler


var physics_velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if disabled:
		return
	physics_update(delta)
	
func physics_update(delta: float) -> void:
	_apply_friction(delta)
	_handle_cell_terrain(delta) # cell stuff, ground effects
	_apply_knockback()
	
	entity.velocity = physics_velocity + locomotion.velocity
	entity.move_and_slide()
	physics_velocity = entity.velocity - locomotion.velocity
	
	
	
	_handle_passive_collisions()
	_handle_bounce_collisions() # knockback purposes
	


func _apply_friction(delta: float) -> void:
	physics_velocity = physics_velocity.move_toward(Vector2.ZERO, delta * friction)
		


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
		
		var relative_velocity: Vector2 = collider_velocity - physics_velocity
		var push_amount: float = relative_velocity.dot(normal)

		if push_amount > 0:
			physics_velocity += normal * push_amount * restitution

	
	
# -------------------------
# knockback
# -------------------------	

func _apply_knockback() -> void:
	if knockback:
		physics_velocity += knockback.knockback_velocity

func _handle_bounce_collisions() -> void:
	if not knockback:
		return
	if entity is not CharacterBody2D:
		return
	if knockback.knockback_velocity.length() > knockback.min_bounce_speed:
		for i in entity.get_slide_collision_count():
			var col: KinematicCollision2D = entity.get_slide_collision(i)
			knockback.knockback_velocity = knockback.knockback_velocity.bounce(col.get_normal()) * knockback.bounce_factor
