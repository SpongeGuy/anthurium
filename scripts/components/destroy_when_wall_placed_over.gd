extends Component
class_name DestroyWhenWallPlacedOver

func _ready() -> void:
	WorldGrid.cell_changed.connect(_on_cell_changed)
	WorldGrid.cells_changed.connect(_on_cells_changed)
	
func _on_cells_changed(batch: Dictionary[Vector2i, CellData]) -> void:
	for coords in batch:
		if coords == WorldGrid.world_to_tile(entity.global_position):
			if batch[coords].terrain == CellData.TerrainType.WALL:
				entity.queue_free()
				
	
func _on_cell_changed(coords: Vector2i, cell: CellData) -> void:
	if coords == WorldGrid.world_to_tile(entity.global_position):
		if cell.terrain == CellData.TerrainType.WALL:
			entity.queue_free()
			
