extends Component
class_name SpawnAlterTerrain

@export var type: Type
@export var radius: int = 2
@export var cell: CellData
enum Type{CIRCLE, SQUARE, SINGULAR}

func _ready() -> void:
	cell.terrain = CellData.TerrainType.GROUND
	cell.invisible = false
	match type:
		Type.CIRCLE:
			call_deferred("_set_circle")
		Type.SQUARE:
			call_deferred("_set_square")
		Type.SINGULAR:
			call_deferred("_set_cell")
			
			
func _set_circle() -> void:
	WorldGrid.set_circle(WorldGrid.world_to_tile(entity.global_position), radius, cell)

func _set_square() -> void:
	WorldGrid.set_rectangle(WorldGrid.world_to_tile(entity.global_position) - Vector2i(radius, radius), Vector2i(radius * 2, radius * 2), cell)

func _set_cell() -> void:
	WorldGrid.set_cell(WorldGrid.world_to_tile(entity.global_position), cell)
