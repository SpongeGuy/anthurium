class_name EmptyTerrainGenerator extends TerrainGenerator

func generate(_rng: RandomNumberGenerator, ground_type: StringName, _wall_type: StringName, indestructible_type: StringName) -> void:
	_fill_walls(ground_type)
	enforce_border(indestructible_type)


func _fill_walls(wall_type: StringName) -> void:
	var wall: CellType = CellTypeRegistry.get_cell_type(wall_type)
	for y in WorldGrid.height:
		for x in WorldGrid.width:
			WorldGrid.get_cell(Vector2i(x, y)).type = wall
