class_name TerrainGenerator extends Resource
func generate(rng: RandomNumberGenerator, ground_type: StringName, wall_type: StringName, indestructible_type: StringName) -> void:
	Log.error("override generate()")


func enforce_border(indestructible_type: StringName) -> void:
	var wall: CellType = CellTypeRegistry.get_cell_type(indestructible_type)
	for x in WorldGrid.width:
		WorldGrid.get_cell(Vector2i(x, 0)).type = wall
		WorldGrid.get_cell(Vector2i(x, WorldGrid.height - 1)).type = wall
	for y in WorldGrid.height:
		WorldGrid.get_cell(Vector2i(0, y)).type = wall
		WorldGrid.get_cell(Vector2i(WorldGrid.width - 1, y)).type = wall
