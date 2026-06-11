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
		
		var col := entity.get_slide_collision(i)
		var normal := col.get_normal()
		
		var relative_velocity := col.get_collider_velocity() - physics_velocity
		var push := relative_velocity.dot(normal)
		if push > 0:
			physics_velocity += normal * push
		
		if col.get_collider() is StaticBody2D or col.get_collider() is TileMapLayer:
			if pre_velocity.length() > min_bounce_speed and pre_velocity.dot(normal) < 0.0:
				physics_velocity = pre_velocity.bounce(normal) * restitution
				wall_collision.emit(col.get_collider())
		elif col.get_collider() is Entity:
			entity_collision.emit(col.get_collider())
