extends Component
class_name NavigationHelper

# -------------------------------------------
# interfaces with a navigation agent to provide some helper functions
# --------------------------------------------

@export var navigation: NavigationAgent2D

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
	navigation.target_reached.connect(_on_target_reached)
	navigation.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED

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

func _on_target_reached() -> void:
	navigation_finished.emit()
	has_target = false

func is_navigating() -> bool:
	return has_target and not navigation.is_target_reached()
