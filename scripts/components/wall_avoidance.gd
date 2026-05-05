extends Component
class_name WallAvoidance

@export var raycast_distance: float = 32.0
@export var avoidance_strength: float = 100.0
@export var num_rays: int = 8
@export var wall_collision_layer: int = 1

var fpos: Vector2

func get_avoidance_vector(from_position: Vector2) -> Vector2:
	fpos = from_position
	var space_state = entity.get_world_2d().direct_space_state
	var avoidance = Vector2.ZERO
	
	# cast rays in a circle around the creature
	for i in range(num_rays):
		var angle = (TAU / num_rays) * i
		var direction = Vector2.RIGHT.rotated(angle)
		var query = PhysicsRayQueryParameters2D.create(
			from_position,
			from_position + direction * raycast_distance
		)
		query.collision_mask = wall_collision_layer
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var result = space_state.intersect_ray(query)
		
		
		if result:
			# hit a wall!
			# calculate avoidance force
			var hit_point = result.position
			var distance = from_position.distance_to(hit_point)
			# stronger avoidance when closer to wall
			var strength = 1.0 - (distance / raycast_distance)
			strength = pow(strength, 2)
			# push away from the wall
			var away_from_wall = (from_position - hit_point).normalized()
			avoidance += away_from_wall * strength
	
	# normalize and apply strength
	if avoidance.length() > 0:
		avoidance = avoidance.normalized() * avoidance_strength
		
		
	return avoidance
	
func _draw() -> void:
	if fpos:
		_draw_debug(fpos)	

# Add to WallAvoidance for debugging
func _draw_debug(from_position: Vector2) -> void:
	print(Engine.is_editor_hint())
	if not Engine.is_editor_hint() and OS.is_debug_build():
		var space_state = entity.get_world_2d().direct_space_state
		
		for i in range(num_rays):
			var angle = (TAU / num_rays) * i
			var direction = Vector2.RIGHT.rotated(angle)
			var end = from_position + direction * raycast_distance
			
			var query = PhysicsRayQueryParameters2D.create(from_position, end)
			query.collision_mask = wall_collision_layer
			var result = space_state.intersect_ray(query)
			
			if result:
				# Red line to hit point
				entity.get_parent().draw_line(
					from_position, result.position, 
					Color.RED, 1.0
				)
			else:
				# Green line for clear path
				entity.get_parent().draw_line(
					from_position, end,
					Color.GREEN, 1.0
				)
