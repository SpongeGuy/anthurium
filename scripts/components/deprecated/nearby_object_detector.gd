extends Component
class_name NearbyObjectDetector

@export var target_groups: Array[String]
@export var search_radius: float = 16

signal object_nearby(object: Node2D)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var target: Node2D = detect_targets(entity.position)
	if target:
		object_nearby.emit(target)


func detect_targets(from_position: Vector2) -> Node2D:
	var best_target: Node2D = null
	var best_distance: float = INF
	
	for group_name in target_groups:
		var potential_targets = entity.get_tree().get_nodes_in_group(group_name)
		for target in potential_targets:
			if target == owner:
				continue
			# entity does not exist?
			if not is_instance_valid(target):
				continue
				
			var to_target = target.global_position - from_position
			var distance = to_target.length()
			
			# too far away?
			if distance > search_radius:
				continue

			if distance < best_distance:
				best_target = target
				best_distance = distance
				
	return best_target
