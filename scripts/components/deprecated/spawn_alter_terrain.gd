extends Component
class_name SpawnAlterTerrain

@export var type: Type
@export var radius: int = 2
@export var cell_type: StringName
enum Type{CIRCLE, SQUARE, SINGULAR}

func _ready() -> void:
	match type:
		Type.CIRCLE:
			call_deferred("_set_circle")
		Type.SQUARE:
			call_deferred("_set_square")
		Type.SINGULAR:
			call_deferred("_set_cell")
			
			
func _set_circle() -> void:
	WorldGrid.set_circle_type(WorldGrid.world_to_tile(entity.global_position), radius, cell_type)

func _set_square() -> void:
	WorldGrid.set_rectangle_type(WorldGrid.world_to_tile(entity.global_position) - Vector2i(radius, radius), Vector2i(radius * 2, radius * 2), cell_type)

func _set_cell() -> void:
	WorldGrid.set_cell_type(WorldGrid.world_to_tile(entity.global_position), cell_type)
