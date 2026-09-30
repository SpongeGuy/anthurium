class_name TerrainSymmetry

enum Mode {NONE, MIRROR_X, MIRROR_Y, MIRROR_XY, ROTATE_180}

static func get_symmetric_positions(pos: Vector2i, mode: Mode) -> Array[Vector2i]:
	var mx: int = WorldGrid.width - 1 - pos.x
	var my: int = WorldGrid.height - 1 - pos.y
	match mode:
		Mode.MIRROR_X:
			return [pos, Vector2i(mx, pos.y)]
		Mode.MIRROR_Y:
			return [pos, Vector2i(pos.x, my)]
		Mode.MIRROR_XY:
			return [pos, Vector2i(mx, pos.y), Vector2i(pos.x, my), Vector2i(mx, my)]
		Mode.ROTATE_180:
			return [pos, Vector2i(mx, my)]
	return [pos]


static func stamp(pos: Vector2i, cell_type: CellType, mode: Mode) -> void:
	for p in get_symmetric_positions(pos, mode):
		if WorldGrid._in_bounds(p):
			WorldGrid.get_cell(p).type = cell_type
