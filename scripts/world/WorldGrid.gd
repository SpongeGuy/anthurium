extends Node
# AUTOLOAD AS WorldGrid

var width: int
var height: int
var _grid: Array[CellData] = []
var _visited: PackedByteArray = []
var _stride: int
var grid_size: Vector2
var tile_size: int = 16
var padding: int = 5

var _batching: bool = false
var _dirty_cells: Dictionary[Vector2i, CellData] = {}
var _smelly_cells: Dictionary[Vector2i, bool] = {}
var _visible_cells: Dictionary[Vector2i, bool] = {}

signal cell_changed(coords: Vector2i, cell: CellData) ## connects to worldrenderer to set a cell visually on the tilemaplayer
signal cells_changed(batch: Dictionary[Vector2i, CellData])
signal cells_visibled(batch: Dictionary[Vector2i, bool])


signal cell_hidden(coords: Vector2i)
signal cell_revealed(coords: Vector2i)
signal grid_loaded

func init_grid(w: int, h: int) -> void:
	width = w
	height = h
	grid_size.x = w
	grid_size.y = h
	_grid.clear()
	_grid.resize((w+(padding * 2))* (h+ (padding * 2))) # padding for out of bounds checking
	_stride = width + (padding * 2)
	
	# initialize entire grid including padding as out of bounds
	for i in _grid.size():
		_grid[i] = CellData.new()
		_grid[i].type = CellTypeRegister.get_cell_type(&"out_of_bounds")
	
	# set the inner area as in bounds
	for y in height:
		for x in width:
			_grid[_idx(Vector2i(x, y))].type = CellTypeRegister.get_cell_type(&"ground_soil")
	
	# initialize visited array
	_visited.resize(_grid.size())
	_visited.fill(0)
	
	grid_loaded.emit()

func safe_get_cell(coords: Vector2i) -> CellData:
	if not _in_bounds(coords):
		return null
	return _grid[_idx(coords)]

func get_cell(coords: Vector2i) -> CellData:
	return _grid[_idx(coords)]

func set_cell(coords: Vector2i, cell: CellData) -> void:
	if _visible_cells.is_empty():
		reveal_from_camera()
	if not _visible_cells.has(coords):
		cell.invisible = true
	var old_cell: CellData = get_cell(coords)
	if old_cell.type.terrain == CellType.TerrainType.OUT_OF_BOUNDS:
		return
	
	_grid[_idx(coords)] = cell # replace with new celldata
	
	if old_cell.type.terrain != cell.terrain and CameraController.target_position and _visible_cells.has(coords):
		reveal_from_camera()
	
	if cell.type.terrain == CellType.TerrainType.GROUND:
		cell.skin = 1
	else:
		cell.skin = 0
		cell.using_random_texture = true
	
	if _batching:
		_dirty_cells[coords] = cell
	else:
		cell_changed.emit(coords, cell)
		
func set_cell_type(coords: Vector2i, type_name: StringName) -> void:
	var cell_type: CellType = CellTypeRegister.get_cell_type(type_name)
	if not cell_type:
		push_warning("WorldGrid: unknown cell type '%s'" % type_name)
		return
	if get_cell(coords).type.terrain == CellType.TerrainType.OUT_OF_BOUNDS:
		return
	var cell: CellData = get_cell(coords)
	if not cell:
		return
	var old_terrain: CellType.TerrainType = cell.type.terrain
	cell.type = cell_type
	cell.max_health = cell_type.max_health
	cell.health = cell_type.max_health
	if old_terrain != cell_type.terrain and CameraController.target_position and _visible_cells.has(coords):
		reveal_from_camera()
	if _batching:
		_dirty_cells[coords] = cell
	else:
		cell_changed.emit(coords, cell)

func hide_cell(coords: Vector2i) -> void:
	var cell = get_cell(coords)
	cell.invisible = true
	_visible_cells.erase(coords)
	if _batching:
		_smelly_cells[coords] = true
	else:
		cell_hidden.emit(coords)
		EventBus.cell_hidden.emit(coords)

func reveal_cell(coords: Vector2i) -> void:
	var cell = get_cell(coords)
	cell.invisible = false
	_visible_cells[coords] = true
	if _batching:
		_smelly_cells[coords] = false
	else:
		cell_revealed.emit(coords)
		EventBus.cell_revealed.emit(coords)

func mutate(coords: Vector2i, property: String, value: Variant) -> void:
	var cell = get_cell(coords)
	if cell and property in cell:
		cell.set(property, value)
		if _batching:
			_dirty_cells[coords] = cell
		else:
			cell_changed.emit(coords, cell)
			
			
func damage_cell(coords: Vector2i, amount: float) -> void:
	var cell: CellData = get_cell(coords)
	if not cell or cell.type.terrain == CellType.TerrainType.OUT_OF_BOUNDS:
		return
	
	
	if cell.take_damage(amount) and cell.type.destroyed_type != &"":
		set_cell_type(coords, cell.type.destroyed_type)
	elif _batching:
		_dirty_cells[coords] = cell
	else:
		cell_changed.emit(coords, cell)
		
func damage_circle(coords: Vector2i, radius: int, amount: float) -> void:
	for y in range(coords.y - radius, coords.y + radius + 1):
		for x in range(coords.x - radius, coords.x + radius + 1):
			var tbc = Vector2i(x, y)
			if _in_bounds(tbc) and Vector2(tbc - coords).length() <= radius:
				damage_cell(tbc, amount)
		
const CARDINAL_DIRS = {
	"N":  Vector2i( 0, -1),
	"S":  Vector2i( 0,  1),
	"E":  Vector2i( 1,  0),
	"W":  Vector2i(-1,  0),
}

const ALL_DIRS = {
	"N":  Vector2i( 0, -1),
	"S":  Vector2i( 0,  1),
	"E":  Vector2i( 1,  0),
	"W":  Vector2i(-1,  0),
	"NE": Vector2i( 1, -1),
	"NW": Vector2i(-1, -1),
	"SE": Vector2i( 1,  1),
	"SW": Vector2i(-1,  1),
}

func get_neighbors(coords: Vector2i, diagonal: bool = false) -> Dictionary[String, CellData]:
	var dirs = ALL_DIRS if diagonal else CARDINAL_DIRS
	var result: Dictionary[String, CellData] = {}
	for key in dirs:
		var neighbor_coords = coords + dirs[key]
		result[key] = get_cell(neighbor_coords)
	return result
	
func get_neighbors_of_type(coords: Vector2i, terrain: CellType.TerrainType, diagonal: bool = false) -> Array[Vector2i]:
	var dirs = ALL_DIRS if diagonal else CARDINAL_DIRS
	var result: Array[Vector2i] = []
	for key in dirs:
		var neighbor_coords = coords + dirs[key]
		var cell = get_cell(neighbor_coords)
		if cell and cell.type and cell.type.terrain == terrain:
			result.append(neighbor_coords)
	return result
	

func _idx(coords: Vector2i) -> int:
	return (coords.y + padding)* _stride + (coords.x + padding)
	
func _in_bounds(coords: Vector2i) -> bool:
	return coords.x >= 0 and coords.x < width and coords.y >= 0 and coords.y < height

# -----------------------------------------
# ------------ helpers --------------------
# -----------------------------------------

# Converts a tile coordinate to the center pixel position of that tile.
func tile_to_world(coords: Vector2i) -> Vector2:
	return Vector2(coords * tile_size) + Vector2(tile_size * 0.5, tile_size * 0.5)

# Converts a pixel world position to the tile coordinate it falls in.
func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(world_pos / tile_size)
	
func get_coords_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	if radius == 0:
		return [center]
	var result: Array[Vector2i] = []
	var x := radius
	var y := 0
	var d := 1 - radius
	while x >= y:
		result.append_array([
			Vector2i(center.x + x, center.y + y),
			Vector2i(center.x - x, center.y + y),
			Vector2i(center.x + x, center.y - y),
			Vector2i(center.x - x, center.y - y),
			Vector2i(center.x + y, center.y + x),
			Vector2i(center.x - y, center.y + x),
			Vector2i(center.x + y, center.y - x),
			Vector2i(center.x - y, center.y - x),
		])
		y += 1
		if d <= 0:
			d += 2 * y + 1
		else:
			x -= 1
			d += 2 * (y - x) + 1
	return result
	
# returns nearest tile coords matching the given terrain type
# searches outward in rings from 'origin'
# returns Vector2i(-1, -1) if none found within max_radius
func get_safe_coords(origin: Vector2i, terrain: CellType.TerrainType, max_radius: int = 64) -> Vector2i:
	for radius in range(0, max_radius):
		for coords in get_coords_in_radius(origin, radius):
			var cell: CellData = safe_get_cell(coords)
			if cell and cell.type and cell.type.terrain == terrain:
				return coords
	return Vector2i(-1, -1)
	
func get_safe_world_pos(origin: Vector2, terrain: CellType.TerrainType, max_radius: int = 64) -> Vector2:
	var coords: Vector2i = get_safe_coords(world_to_tile(origin), terrain, max_radius)
	if coords == Vector2i(-1, -1):
		return Vector2.INF
	return tile_to_world(coords)

func set_rectangle_type(position: Vector2i, size: Vector2i, type_name: StringName) -> void:
	var rectangle: Rect2i = Rect2i(position, size)
	for y in range(rectangle.position.y, rectangle.position.y + rectangle.size.y):
		for x in range(rectangle.position.x, rectangle.position.x + rectangle.size.x):
			set_cell_type(Vector2i(x, y), type_name)


func set_circle_type(center: Vector2i, radius: int, type_name: StringName, filled: bool = true) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var coords = Vector2i(x, y)
			if not _in_bounds(coords):
				continue
			var dist = Vector2(coords - center).length()
			if (filled and dist <= radius) or (not filled and dist <= radius and dist > radius - 1.0):
				set_cell_type(coords, type_name)

# ------------------------------------
# util visibility
# -------------------------------------

func reveal_from_camera() -> void:
	if not CameraController.target_position:
		await EventBus.camera_target_changed
	reveal_from(world_to_tile(CameraController.target_position))
	
	
func hide_map() -> void:
	for y in height:
		for x in width:
			hide_cell(Vector2i(x, y))
	
func hide_visible_cells() -> void:
	for cell in _visible_cells.keys():
		hide_cell(cell)
	_visible_cells.clear()

func begin_batch() -> void:
	_dirty_cells.clear()
	_smelly_cells.clear()
	_batching = true
	
func end_batch() -> void:
	_batching = false
	if _dirty_cells.size() > 0:
		cells_changed.emit(_dirty_cells)
		_dirty_cells.clear()
	if _smelly_cells.size() > 0:
		cells_visibled.emit(_smelly_cells)
		EventBus.cells_visibled.emit(_smelly_cells)
		
func is_world_pos_visible(world_pos: Vector2) -> bool:
	var cell: CellData = safe_get_cell(world_to_tile(world_pos))
	return cell != null and not cell.invisible
	

func _idx_to_coords(idx: int) -> Vector2i:
	return Vector2i(idx % _stride - padding, idx / _stride - padding)

func flood_collect(coords: Vector2i) -> Array:
	_visited.fill(0)
	
	const UNVISITED: int = 0
	const FLOODED: int = 1
	const BORDER: int = 2
	
	var start: int = _idx(coords)
	if _grid[start].type.terrain != CellType.TerrainType.GROUND:
		return [[] as Array[Vector2i], [] as Array[Vector2i]]
		
	var cardinal: Array[int] = [-_stride, 1, _stride, -1]
	var diagonal: Array[int] = [-_stride - 1, -_stride + 1, _stride - 1, _stride + 1]
	
	var flooded: Array[Vector2i] = []
	var border: Array[Vector2i] = []
	var queue: Array[int] = [start]
	_visited[start] = FLOODED
	
	while not queue.is_empty():
		var current: int = queue.pop_back()
		flooded.append(_idx_to_coords(current))
		
		for offset in cardinal:
			var n: int = current + offset
			if _visited[n] != UNVISITED:
				continue
			if _grid[n].type.terrain == CellType.TerrainType.GROUND:
				_visited[n] = FLOODED
				queue.push_back(n)
			elif _grid[n].type.terrain != CellType.TerrainType.OUT_OF_BOUNDS:
				_visited[n] = BORDER
				border.append(_idx_to_coords(n))
		
		for offset in diagonal:
			var n: int = current + offset
			if _visited[n] != UNVISITED:
				continue
			if _grid[n].type.terrain != CellType.TerrainType.GROUND and _grid[n].type.terrain != CellType.TerrainType.OUT_OF_BOUNDS:
					_visited[n] = BORDER
					border.append(_idx_to_coords(n))
		
	return [flooded, border]

func reveal_from(coords: Vector2i) -> void:
	var result:= flood_collect(coords)
	var flooded: Array[Vector2i] = result[0]
	var border: Array[Vector2i] = result[1]
	
	begin_batch()
	hide_visible_cells()
	for tile in flooded: reveal_cell(tile)
	for tile in border: reveal_cell(tile)
	end_batch()


func flush_all() -> void:
	begin_batch()
	for y in height:
		for x in width:
			var coords = Vector2i(x, y)
			var cell = get_cell(coords)
			if cell.type.terrain == CellType.TerrainType.OUT_OF_BOUNDS:
				continue
			_dirty_cells[coords] = cell
	end_batch()
