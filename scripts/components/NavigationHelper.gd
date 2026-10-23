extends Component
class_name NavigationHelper

# -------------------------------------------
# interfaces with a navigation agent to provide some helper functions
# --------------------------------------------

@export var navigation: NavigationAgent2D
@export var arrive_distance: float = 4.0

signal picked_new_nav_point(target_position: Vector2i)
signal navigation_finished
signal navigation_cancelled

var has_target: bool = false

var disabled: bool = false

# --------------------------------------------------------------------------------------------
# has_target = false + is_navigation_finished() = true  → idle, no order given
# has_target = true  + is_navigation_finished() = false → actively navigating
# has_target = true  + is_navigation_finished() = true  → just arrived
# --------------------------------------------------------------------------------------------

func _ready() -> void:
	#navigation.target_reached.connect(_on_target_reached)
	navigation.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_CORRIDORFUNNEL
	#navigation.path_desired_distance = 4
	#navigation.target_desired_distance = 25

func _arrival_radius() -> float:
	return maxf(arrive_distance, navigation.target_desired_distance)

func stop_navigation() -> void:
	navigation.set_target_position(entity.global_position)
	has_target = false
	navigation_cancelled.emit()

func set_new_pathfinding_location_relative(origin: Vector2, min_radius: float, max_radius: float) -> Vector2:
	var angle: float = randf() * TAU
	var distance = randf_range(min_radius, max_radius)
	var target_position: Vector2 = origin + Vector2(cos(angle), sin(angle)) * distance
	target_position = WorldGrid.get_safe_world_pos(target_position, CellType.TerrainType.GROUND)
	navigation.set_target_position(target_position)
	picked_new_nav_point.emit(target_position)
	has_target = true
	return target_position
	
func set_new_pathfinding_location_relative_explicit_angle(origin: Vector2, min_radius: float, max_radius: float, angle: float, angle_variance: float) -> Vector2:
	var offset_angle: float = randf_range(-angle_variance, angle_variance)
	var final_angle: float = wrapf(angle + offset_angle, 0.0, TAU)
	var distance: float = randf_range(min_radius, max_radius)
	var target_position: Vector2 = origin + Vector2(cos(final_angle), sin(final_angle)) * distance
	target_position = WorldGrid.get_safe_world_pos(target_position, CellType.TerrainType.GROUND)
	navigation.set_target_position(target_position)
	picked_new_nav_point.emit(target_position)
	has_target = true
	return target_position

func set_new_pathfinding_location_explicit(position: Vector2, safe: bool = true) -> void:
	if safe:
		var safe_position: Vector2 = WorldGrid.get_safe_world_pos(position, CellType.TerrainType.GROUND)
		navigation.set_target_position(safe_position)
	else:
		navigation.set_target_position(position)
		
	has_target = true
	

func get_next_path_position() -> Vector2:
	return navigation.get_next_path_position()

func get_next_path_direction() -> Vector2:
	var direction: Vector2 = (navigation.get_next_path_position() - entity.global_position).normalized()
	return direction
	
func has_arrived() -> bool:
	if not has_target:
		return true
	var pos: Vector2 = entity.global_position
	var r: float = _arrival_radius()
	if pos.distance_to(navigation.target_position) <= r:
		return true
	return navigation.is_navigation_finished() and pos.distance_to(navigation.get_final_position()) <= r


func is_navigating() -> bool:
	if has_target and has_arrived():
		_finish()
	return has_target

func _finish() -> void:
	if not has_target:
		return
	has_target = false
	navigation_finished.emit()

func is_target_reachable() -> bool:
	return navigation.is_target_reachable()

func get_final_position() -> Vector2:
	return navigation.get_final_position()

func _on_target_reached() -> void:
	navigation_finished.emit()
	has_target = false
