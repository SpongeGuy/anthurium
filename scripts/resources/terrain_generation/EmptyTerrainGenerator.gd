class_name EmptyTerrainGenerator extends TerrainGenerator

func generate(_rng: RandomNumberGenerator, ground_type: StringName, _wall_type: StringName, indestructible_type: StringName) -> void:
	WorldGrid.set_rectangle_type(Vector2i(0, 0), Vector2i(WorldGrid.width, WorldGrid.height), ground_type)
	var border: CellType = CellTypeRegistry.get_cell_type(indestructible_type)
	for x in WorldGrid.width:
		WorldGrid.get_cell(Vector2i(x, 0)).type = border
		WorldGrid.get_cell(Vector2i(x, WorldGrid.height - 1)).type = border
	for y in WorldGrid.height:
		WorldGrid.get_cell(Vector2i(0, y)).type = border
		WorldGrid.get_cell(Vector2i(WorldGrid.width - 1, y)).type = border
