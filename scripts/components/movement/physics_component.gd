extends Component
class_name PhysicsComponent

@export var disabled: bool = false

@export var mass: float = 1.0
@export var friction_coefficient: float = 1.0
@export var base_friction: float = 800
@export var restitution: float = 0.4
@export var min_bounce_speed: float = 40.0
@export var max_speed: float = 1000.0
@export var world_interface: WorldInterface
@export var locomotion: LocomotionHandler

## Maximum speed (px/s) at which overlapping entities are nudged apart.
const OVERLAP_SEPARATION_SPEED: float = 1500.0
## Minimum penetration depth (px) ebfore the separation nudge activates.
const OVERLAP_DEPTH_THRESHOLD: float = 1.0

var physics_velocity: Vector2 = Vector2.ZERO
var _accumulated_force: Vector2 = Vector2.ZERO

signal wall_collision(source: Node)
signal entity_collision(source: Entity)

func _on_registered() -> void:
	pass # replace with function body

func _physics_process(delta: float) -> void:
	if disabled:
		return
	physics_update(delta)
	
func physics_update(delta: float) -> void:
	_apply_forces(delta)
	_apply_friction(delta)
	_handle_cell_terrain(delta)
	
		
	var pre_slide_velocity: Vector2 = physics_velocity
		
	entity.velocity = physics_velocity + (locomotion.velocity if locomotion else Vector2.ZERO)
	entity.move_and_slide()
	physics_velocity = entity.velocity - (locomotion.velocity if locomotion else Vector2.ZERO)
	
	_handle_collisions(pre_slide_velocity)

func clear_velocity() -> void:
	physics_velocity = Vector2.ZERO

func apply_impulse(direction: Vector2, magnitude: float) -> void:
	physics_velocity += direction.normalized() * (magnitude / mass)

func apply_force(direction: Vector2, magnitude: float) -> void:
	_accumulated_force += direction.normalized() * magnitude
	

func _apply_forces(delta: float) -> void:
	physics_velocity += (_accumulated_force / mass) * delta
	_accumulated_force = Vector2.ZERO
	physics_velocity = physics_velocity.limit_length(max_speed)
	
func _apply_friction(delta: float) -> void:
	var deceleration: float = base_friction * friction_coefficient * (1.0 / mass)
	physics_velocity = physics_velocity.move_toward(Vector2.ZERO, deceleration * delta)
	
func _handle_cell_terrain(_delta: float) -> void:
	if not world_interface:
		return
			

func _handle_collisions(pre_velocity: Vector2) -> void:
	for i in entity.get_slide_collision_count():
		var col: KinematicCollision2D = entity.get_slide_collision(i)
		var normal: Vector2 = col.get_normal()
		var collider: Object = col.get_collider()
		
		
		
		if collider is StaticBody2D or collider is TileMapLayer:
			# moving platform support: inherit velocity only from physical surfaces
			var relative_velocity: Vector2 = col.get_collider_velocity() - physics_velocity
			var push: float = relative_velocity.dot(normal)
			if push > 0:
				physics_velocity += normal * push
			
			if pre_velocity.length() > min_bounce_speed and pre_velocity.dot(normal) < 0.0:
				physics_velocity = pre_velocity.bounce(normal) * restitution
				wall_collision.emit(col.get_collider())
		 
		elif collider is Entity:
			
			# cancel any velocity component driving us further into the other entity
			var into_normal: float = physics_velocity.dot(normal)
			if into_normal < 0.0:
				physics_velocity -= normal * into_normal
				
			# gentle positional separation for deep overlaps (e.g. spawned on top)
			var depth: float = col.get_depth()
			if depth > OVERLAP_DEPTH_THRESHOLD:
				entity.global_position += Vector2.from_angle(randf() * TAU)
					
			entity_collision.emit(col.get_collider())
