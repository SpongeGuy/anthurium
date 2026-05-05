extends TileMapLayer
class_name WorldRenderer


const MAPPING: PackedByteArray = [128, 64, 32, 16, 8, 4, 2, 1]
static var DIRECTIONS: Array[Vector2i] = [
	Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
	Vector2i(-1, 0),                 Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
]
	
const OLD_TERRAIN_ATLAS: Dictionary = {
	CellData.TerrainType.GROUND: Vector2i(0, 0),
	CellData.TerrainType.WALL: Vector2i(1, 0),
	CellData.TerrainType.GAP: Vector2i(2, 0),
}

static var BITMASK_TABLE: Array[Vector2i] = _build_bitmask_table()

func _ready() -> void:
	WorldGrid.cell_changed.connect(_on_cell_changed)
	WorldGrid.cells_changed.connect(_on_cells_changed)
	
func _on_cell_changed(coords: Vector2i, cell: CellData) -> void:
	_draw_cell(coords, cell)
	
func _on_cells_changed(batch: Dictionary[Vector2i, CellData]) -> void:
	for coordinate in batch:
		_draw_cell(coordinate, batch[coordinate])
	
func _draw_cell(coords: Vector2i, cell: CellData) -> void:
	cell.atlas_coordinate = resolve_atlas_coordinate(cell, coords)
	set_cell(coords, cell.skin, cell.atlas_coordinate)
	_redraw_neighbors(coords)
	
func render_all() -> void:
	for y in WorldGrid.height:
		for x in WorldGrid.width:
			var coords = Vector2i(x, y)
			var cell: CellData = WorldGrid.get_cell(coords)
			_draw_cell(coords, cell)
			

func resolve_atlas_coordinate(cell: CellData, coords: Vector2i) -> Vector2i:

	if cell.using_random_texture:
		var source: TileSetAtlasSource = tile_set.get_source(cell.skin) as TileSetAtlasSource
		var texture_size: Vector2 = source.texture.get_size()
		var tile_size: Vector2i = source.texture_region_size
		var columns: int = int(texture_size.x / tile_size.x)
		var rows: int = int(texture_size.y / tile_size.y)
		return Vector2i(randi() % columns, randi() % rows)
	
	var bitmask: int = 0
	for i in range(DIRECTIONS.size()):
		var neighbor: CellData = WorldGrid.get_cell(coords + DIRECTIONS[i])
		if cell.terrain == neighbor.terrain:
			bitmask += MAPPING[i]
	
	return BITMASK_TABLE[_normalize(bitmask)]

func _normalize(m: int) -> int:
	if not ((m & 64) and (m & 16)): m &= ~128  # NW requires N and W
	if not ((m & 64) and (m & 8)):  m &= ~32   # NE requires N and E
	if not ((m & 2)  and (m & 16)): m &= ~4    # SW requires S and W
	if not ((m & 2)  and (m & 8)):  m &= ~1    # SE requires S and E
	return m
	
func _redraw_neighbors(coords: Vector2i) -> void:
	for dir in DIRECTIONS:
		var nc: Vector2i = coords + dir
		var neighbor: CellData = WorldGrid.get_cell(nc)
		if neighbor == null or neighbor.terrain == CellData.TerrainType.OUT_OF_BOUNDS:
			continue
		neighbor.atlas_coordinate = resolve_atlas_coordinate(neighbor, nc)
		set_cell(nc, neighbor.skin, neighbor.atlas_coordinate)


static func _build_bitmask_table() -> Array[Vector2i]:
	var t: Array[Vector2i] = []
	t.resize(256)
	t.fill(Vector2i(1, 1)) # fallback: fully surrounded tile
	
	# row 0
	t[11]  = Vector2i(0, 0)
	t[31]  = Vector2i(1, 0)
	t[22]  = Vector2i(2, 0)
	t[2]   = Vector2i(3, 0)
	t[10]  = Vector2i(4, 0)
	t[30]  = Vector2i(5, 0)
	t[27]  = Vector2i(6, 0)
	t[18]  = Vector2i(7, 0)
	t[26]  = Vector2i(8, 0)
	t[219] = Vector2i(9, 0)
	# row 1
	t[107] = Vector2i(0, 1)
	t[255] = Vector2i(1, 1)
	t[214] = Vector2i(2, 1)
	t[66]  = Vector2i(3, 1)
	t[106] = Vector2i(4, 1)
	t[254] = Vector2i(5, 1)
	t[251] = Vector2i(6, 1)
	t[210] = Vector2i(7, 1)
	t[250] = Vector2i(8, 1)
	t[126] = Vector2i(9, 1)
	# row 2
	t[104] = Vector2i(0, 2)
	t[248] = Vector2i(1, 2)
	t[208] = Vector2i(2, 2)
	t[64]  = Vector2i(3, 2)
	t[75]  = Vector2i(4, 2)
	t[223] = Vector2i(5, 2)
	t[127] = Vector2i(6, 2)
	t[86]  = Vector2i(7, 2)
	t[95]  = Vector2i(8, 2)
	t[91]  = Vector2i(9, 2)
	t[94]  = Vector2i(10, 2)
	# row 3
	t[8]   = Vector2i(0, 3)
	t[24]  = Vector2i(1, 3)
	t[16]  = Vector2i(2, 3)
	t[0]   = Vector2i(3, 3)
	t[72]  = Vector2i(4, 3)
	t[216] = Vector2i(5, 3)
	t[120] = Vector2i(6, 3)
	t[80]  = Vector2i(7, 3)
	t[88]  = Vector2i(8, 3)
	t[122] = Vector2i(9, 3)
	t[218] = Vector2i(10, 3)
	# row 4
	t[74]  = Vector2i(4, 4)
	t[222] = Vector2i(5, 4)
	t[123] = Vector2i(6, 4)
	t[82]  = Vector2i(7, 4)
	t[90]  = Vector2i(8, 4)
	
	return t
