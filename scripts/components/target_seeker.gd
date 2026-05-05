extends Component
class_name TargetSeeker

signal target_found(target: Node2D)
signal target_lost()

@export var detection_radius: float = 128.0
@export var target_groups: Array[String] = ["food"]
@export var vision_angle: float = 360.0
@export var wall_collision_layer: int = 1
@export var friends: FriendComponent
@export var can_target_self: bool = false
@export var can_target_friends: bool = false

## when disabled, will reduce calculation time
@export var check_for_LOS: bool = true


var current_target: Node2D = null
var last_known_position: Vector2

func find_nearest_target(from_position: Vector2, facing_direction: Vector2) -> Node2D:
	var best_target: Node2D = null
	var best_distance: float = INF
	
	for group_name in target_groups:
		var potential_targets = entity.get_tree().get_nodes_in_group(group_name)
		
		for target in potential_targets:
			# entity does not exist?
			if not is_instance_valid(target):
				continue

			if not can_target_self and target == owner:
				continue
				
			if friends and (not can_target_friends and friends.is_friend(target)):
				continue
				
			var to_target = target.global_position - from_position
			var distance = to_target.length()
			
			# too far away?
			
			if distance > detection_radius:
				continue
				
			
			if check_for_LOS:
				# outside vision cone?
				if vision_angle < 360.0:
					var angle_to_target = facing_direction.angle_to(to_target)
					if abs(angle_to_target) > deg_to_rad((vision_angle) / 2.0):
						continue
						
				# line of sight check; can we actually see it?
				if not has_line_of_sight(from_position, target.global_position):
					continue
			
			if distance < best_distance:
				best_target = target
				best_distance = distance
		
	if best_target != current_target:
		if current_target != null:
			target_lost.emit()
		if best_target != null:
			target_found.emit(best_target)
		current_target = best_target
		
	if best_target:
		last_known_position = best_target.global_position
		
	return best_target
	
func has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	var space_state = entity.get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = wall_collision_layer
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [owner]
	
	var result = space_state.intersect_ray(query)
	
	if not result:
		return true
		
	var hit_distance = from.distance_to(result.position)
	var target_distance = from.distance_to(to)
	
	return hit_distance >= target_distance
	
func get_direction_to_target(from_position: Vector2) -> Vector2:
	if current_target and is_instance_valid(current_target):
		return (current_target.global_position - from_position).normalized()
	elif last_known_position:
		# move toward last known position if we lost sight
		return (last_known_position - from_position).normalized()
	return Vector2.ZERO 
