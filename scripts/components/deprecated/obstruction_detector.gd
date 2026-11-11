extends Component
class_name ObstructionDetector

# -----------------------------------------------------
# interfaces with an area2d to detect nearby terrain
# holds a boolean state reflecting whether the area is currently overlapping a tilemaplayer
# can also perform a one-shot point query to check for any body at a given world position
# -----------------------------------------------------

@export var area: Area2D

var is_facing_obstruction: bool = false

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(other: Node2D) -> void:
	if other is TileMapLayer:
		is_facing_obstruction = true

func _on_body_exited(other: Node2D) -> void:
	if other is TileMapLayer:
		is_facing_obstruction = false

func has_body_at(world_pos: Vector2, mask: int) -> bool:
	var space: PhysicsDirectSpaceState2D = entity.get_world_2d().direct_space_state
	var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	params.position = world_pos
	params.collision_mask = mask
	params.collide_with_areas = true
	params.collide_with_bodies = true
	return not space.intersect_point(params, 1).is_empty()
