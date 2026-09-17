extends Component
class_name PhysicsComponent

@export var disabled: bool = false

@export var friction_coefficient: float = 1.0
@export var base_friction: float = 800
@export_range(0, 1) var restitution: float = 0.4
@export var min_bounce_speed: float = 40.0
@export var max_speed: float = 1000.0
@export var world_interface: WorldInterface
@export var locomotion: LocomotionHandler

@export var knockback_minimum_force: float = 0.0
@export var knockback_scale: float = 1.0

## Maximum speed (px/s) at which overlapping entities are nudged apart.
const OVERLAP_SEPARATION_SPEED: float = 1500.0
## Minimum penetration depth (px) ebfore the separation nudge activates.
const OVERLAP_DEPTH_THRESHOLD: float = 1.0

var physics_velocity: Vector2 = Vector2.ZERO
var _accumulated_force: Vector2 = Vector2.ZERO
var _z_excepted: Dictionary[Entity, bool] = {}

signal wall_collision(source: Node)
signal entity_collision(source: Entity)

func _on_registered() -> void:
	pass # replace with function body

func _physics_process(delta: float) -> void:
	if disabled:
		return
	physics_update(delta)
	
func physics_update(delta: float) -> void:
	_update_z_collision_exceptions()
	_apply_forces(delta)
	_apply_friction(delta)
	_handle_cell_terrain(delta)
	
		
	var locomotion_velocity: Vector2 = locomotion.velocity if locomotion else Vector2.ZERO
	var pre_slide_velocity: Vector2 = physics_velocity
	var pre_slide_full: Vector2 = physics_velocity + locomotion_velocity
		
	entity.velocity = pre_slide_full
	entity.move_and_slide()
	physics_velocity = entity.velocity - locomotion_velocity
	
	
	
	_handle_collisions(pre_slide_velocity, pre_slide_full)

func clear_velocity() -> void:
	physics_velocity = Vector2.ZERO

func apply_impulse(direction: Vector2, magnitude: float) -> void:
	physics_velocity += direction.normalized() * (magnitude / entity.mass)

func apply_force(direction: Vector2, magnitude: float) -> void:
	_accumulated_force += direction.normalized() * magnitude
	
func apply_knockback(source_position: Vector2, force: float) -> void:
	var scaled_force: float = force * knockback_scale
	if scaled_force < knockback_minimum_force:
		return
	var direction: Vector2 = (entity.global_position - source_position).normalized()
	apply_impulse(direction, scaled_force)

func _apply_forces(delta: float) -> void:
	physics_velocity += (_accumulated_force / entity.mass) * delta
	_accumulated_force = Vector2.ZERO
	physics_velocity = physics_velocity.limit_length(max_speed)
	
func _apply_friction(delta: float) -> void:
	var deceleration: float = base_friction * friction_coefficient * (1.0 / entity.mass)
	physics_velocity = physics_velocity.move_toward(Vector2.ZERO, deceleration * delta)
	
func _handle_cell_terrain(_delta: float) -> void:
	if not world_interface:
		return
		
		
func _update_z_collision_exceptions() -> void:
	if not entity.is_initialized:
		return
	if is_zero_approx(entity.z):
		return
	var space_state: PhysicsDirectSpaceState2D = entity.get_world_2d().direct_space_state
	var nearby: Array[Entity] = SpatialUtil.get_entities_in_radius(space_state, entity.position, 16, SpatialUtil.PhysicsLayers.CREATURES)
	var still_relevant: Dictionary[Entity, bool] = {}
	
	for other in nearby:
		if other == entity or not is_instance_valid(other):
			continue
		var overlaps: bool = SpatialUtil.z_ranges_overlap(entity.z, entity.height, other.z, other.height)
		if not overlaps:
			if not _z_excepted.has(other):
				entity.add_collision_exception_with(other)
				other.add_collision_exception_with(entity)
			still_relevant[other] = true
		elif _z_excepted.has(other):
			entity.remove_collision_exception_with(other)
			other.remove_collision_exception_with(entity)
	
	# clean up anything that fell out of range or got freed
	for other in _z_excepted.keys():
		if not still_relevant.has(other):
			if is_instance_valid(other):
				entity.remove_collision_exception_with(other)
				other.remove_collision_exception_with(entity)
				
	_z_excepted = still_relevant

func _handle_collisions(pre_velocity: Vector2, pre_full: Vector2) -> void:
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
			# different vertical spans (e.g. a flying entity passing over a
			# burrowing one) don't push or shove each other. note: this only
			# stops the *lasting* force; move_and_slide() has already
			# resolved this frame's position against the raw 2D shape, so a
			# one-frame graze can still occur. see SpatialUtil.z_ranges_overlap.
			if not SpatialUtil.z_ranges_overlap(entity.z, entity.height, collider.z, collider.height):
				continue
			
			var other_physics: PhysicsComponent = collider.get_component(PhysicsComponent)
			var into_normal: float = pre_full.dot(normal)
			
			if other_physics:
				if into_normal < 0.0:
					var m1: float = entity.mass
					var m2: float = collider.mass
					var is_dominant: bool = m1 > m2 or (m1 == m2 and entity.get_instance_id() < collider.get_instance_id())
					
					if is_dominant:
						var total: float = m1 + m2
						# project both velocities onto the A->B axis
						var axis: Vector2 = -normal
						var v_a: float = -into_normal
						var v_b: float = other_physics.physics_velocity.dot(axis)
						
						# generalized restitution formula (e=1: elastic, e=0: inelastic)
						var e: float = (restitution + other_physics.restitution) * 0.5
						var new_va: float = (m1 * v_a + m2 * v_b + m2 * e * (v_b - v_a)) / total
						var new_vb: float = (m1 * v_a + m2 * v_b + m1 * e * (v_a - v_b)) / total
						
						physics_velocity += axis * (new_va - v_a)
						other_physics.physics_velocity += axis * (new_vb - v_b)
						
			else:
				if into_normal < 0.0:
					physics_velocity -= normal * into_normal
				
			# gentle positional separation for deep overlaps (e.g. spawned on top)
			var depth: float = col.get_depth()
			if depth > OVERLAP_DEPTH_THRESHOLD:
				entity.global_position += Vector2.from_angle(randf() * TAU)
					
			entity_collision.emit(col.get_collider())
