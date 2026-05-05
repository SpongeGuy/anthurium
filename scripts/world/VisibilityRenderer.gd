extends TileMapLayer
class_name VisibilityRenderer

const ATLAS_SOURCE_ID: int = 0
var visible_atlas_uv: Vector2i = Vector2i(3, 1)
var invisible_atlas_uv: Vector2i = Vector2i(3, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WorldGrid.cell_hidden.connect(_on_cell_hidden)
	WorldGrid.cell_revealed.connect(_on_cell_revealed)
	WorldGrid.cells_visibled.connect(_on_cells_visibled)



func _on_cells_visibled(batch: Dictionary[Vector2i, bool]) -> void:
	for tile in batch:
		if batch[tile] == true:
			_on_cell_hidden(tile)
		else:
			_on_cell_revealed(tile)
	
func _on_cell_hidden(coords: Vector2i) -> void:
	_draw_cell(coords, invisible_atlas_uv)
	
func _on_cell_revealed(coords: Vector2i) -> void:
	_draw_cell(coords, visible_atlas_uv)

func _draw_cell(coords: Vector2i, uv: Vector2i) -> void:
	set_cell(coords, ATLAS_SOURCE_ID, uv)
