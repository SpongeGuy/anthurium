## Autoload: WorldGrid
##
## Owns the tile grid backing the playable world: cell data storage, terrain
## mutation, fog-of-war visibility (flood-fill reveal), and neighbor/radius
## queries used by pathing, spawning, and world generation. Grid contents are
## padded on every side so out-of-bounds lookups return a valid (but
## [constant CellType.TerrainType.OUT_OF_BOUNDS]) cell instead of erroring.
##
## Call [method init_grid] once to size and initialize the grid before
## anything else touches it (see [DungeonGenerator]).
extends Node
# AUTOLOAD AS WorldGrid

## Grid width, in tiles, excluding padding.
var width: int
## Grid height, in tiles, excluding padding.
var height: int
## Flat backing storage for every [CellData], including the padded border.
var _grid: Array[CellData] = []
## Scratch visited-flags buffer reused by [method flood_collect].
var _visited: PackedByteArray = []
## Row stride (width + padding on both sides) used by [method _idx].
var _stride: int
## [member width]/[member height] packed as a [Vector2], for convenience.
var grid_size: Vector2
## Size, in pixels, of one tile's edge.
var tile_size: int = 16
## Extra out-of-bounds tiles kept on every side of the grid so neighbor
## lookups near the edge never go out of array range.
var padding: int = 5

## Whether cell-change/visibility signals are being batched instead of
## emitted immediately. See [method begin_batch]/[method end_batch].
var _batching: bool = false
## Cells changed while [member _batching] is active, flushed by
## [method end_batch] as [signal cells_changed].
var _dirty_cells: Dictionary[Vector2i, CellData] = {}
## Visibility changes accumulated while [member _batching] is active,
## flushed by [method end_batch] as [signal cells_visibled].
var _smelly_cells: Dictionary[Vector2i, bool] = {}
## Tiles currently revealed (not fogged), maintained by
## [method reveal_cell]/[method hide_cell].
var _visible_cells: Dictionary[Vector2i, bool] = {}

signal cell_changed(coords: Vector2i, cell: CellData) ## connects to worldrenderer to set a cell visually on the tilemaplayer
## Emitted with a batch of changed cells when a batch ends with dirty cells.
## See [method begin_batch]/[method end_batch].
signal cells_changed(batch: Dictionary[Vector2i, CellData])
## Emitted with a batch of visibility changes when a batch ends with pending
## ones. See [method begin_batch]/[method end_batch].
signal cells_visibled(batch: Dictionary[Vector2i, bool])


## Emitted when a single tile becomes hidden (outside of a batch).
signal cell_hidden(coords: Vector2i)
## Emitted when a single tile becomes revealed (outside of a batch).
signal cell_revealed(coords: Vector2i)
## Emitted once [method init_grid] has finished (re)initializing the grid.
signal grid_loaded

## Allocates and resets the grid to [param w] x [param h] tiles (plus
## [member padding] on every side), fills the interior with
## [code]&"ground_soil"[/code] and the border/padding with
## [code]&"out_of_bounds"[/code], and resets the flood-fill visited buffer.
## Emits [signal grid_loaded] when finished.
func init_grid(w: int, h: int) -> void:
	width = w
	height = h
	grid_size.x = w
	grid_size.y = h
	_grid.clear()
	_grid.resize((w+(padding * 2))* (h+ (padding * 2))) # padding for out of bounds checking
	_stride = width + (padding * 2)
	
	_visible_cells.clear()
	_dirty_cells.clear()
	_smelly_cells.clear()
	_batching = false
	
	# initialize entire grid including padding as out of bounds
	for i in _grid.size():
		_grid[i] = CellData.new()
		_grid[i].type = CellTypeRegistry.get_cell_type(&"out_of_bounds")
	
	# set the inner area as in bounds
	for y in height:
		for x in width:
			_grid[_idx(Vector2i(x, y))].type = CellTypeRegistry.get_cell_type(&"ground_soil")
	
	# initialize visited array
	_visited.resize(_grid.size())
	_visited.fill(0)
	
	Log.info("Grid initialized!")
	grid_loaded.emit()

## Returns the [CellData] at [param coords], or [code]null[/code] if
## [param coords] is outside [member width]/[member height]. Prefer this over
## [method get_cell] when [param coords] isn't already known to be in bounds.
func safe_get_cell(coords: Vector2i) -> CellData:
	if not _in_bounds(coords):
		return null
	return _grid[_idx(coords)]

## Returns the [CellData] at [param coords], including padding cells.
## Does not bounds-check; use [method safe_get_cell] if [param coords]
## might be arbitrary.
func get_cell(coords: Vector2i) -> CellData:
	return _grid[_idx(coords)]
	
func get_center() -> Vector2i:
	return Vector2i(floor(width / 2), floor(height / 2))
	
func get_random_coords_of_type(terrain_type: CellType.TerrainType, rng: RandomNumberGenerator) -> Vector2i:
	var matches: Array[Vector2i] = []
	for x in width:
		for y in height:
			var pos: Vector2i = Vector2i(x, y)
			if get_cell(pos).type.terrain == terrain_type:
				matches.append(pos)
	if matches.is_empty():
		return get_center()
	return matches[rng.randi_range(0, matches.size() - 1)]

	
func get_random_ground_tile(rng: RandomNumberGenerator) -> Vector2i:
	return get_random_coords_of_type(CellType.TerrainType.GROUND, rng)

	

## Replaces the cell at [param coords] with [param cell] wholesale. Marks
## the new cell invisible if it falls outside currently visible tiles,
## refuses to overwrite out-of-bounds cells, re-derives the [code]skin[/code]
## for the new terrain, and emits [signal cell_changed] (or queues it if
## batching).
func set_cell(coords: Vector2i, cell: CellData) -> void:
	if _visible_cells.is_empty():
		CameraController.reveal_from_camera()
	if not _visible_cells.has(coords):
		cell.invisible = true
	var old_cell: CellData = get_cell(coords)
	if old_cell.type.terrain == CellType.TerrainType.OUT_OF_BOUNDS:
		return
	
	_grid[_idx(coords)] = cell # replace with new celldata
	
	if old_cell.type.terrain != cell.terrain and CameraController.target_position and _visible_cells.has(coords):
		CameraController.reveal_from_camera()
	
	#if cell.type.terrain == CellType.TerrainType.GROUND:
		#cell.skin = 1
	#else:
		#cell.skin = 0
		#cell.using_random_texture = true
	
	if _batching:
		_dirty_cells[coords] = cell
	else:
		cell_changed.emit(coords, cell)
		
## Changes the terrain of the cell at [param coords] to [param type_name],
## resetting its health to the new type's max. No-op on unknown types,
## out-of-bounds cells, or a missing cell. Re-reveals from the camera if the
## terrain changed on a currently visible tile, and emits [signal cell_changed]
## (or queues it if batching).
func set_cell_type(coords: Vector2i, type_name: StringName) -> void:
	var cell_type: CellType = CellTypeRegistry.get_cell_type(type_name)
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
		CameraController.reveal_from_camera()
	if _batching:
		_dirty_cells[coords] = cell
	else:
		cell_changed.emit(coords, cell)

## Marks the tile at [param coords] as hidden (fog-of-war), removing it from
## [member _visible_cells] and emitting [signal cell_hidden] and
## [signal EventBus.cell_hidden] (or queuing the visibility change if
## batching).
func hide_cell(coords: Vector2i) -> void:
	var cell = get_cell(coords)
	cell.invisible = true
	_visible_cells.erase(coords)
	if _batching:
		_smelly_cells[coords] = true
	else:
		cell_hidden.emit(coords)
		EventBus.cell_hidden.emit(coords)

## Marks the tile at [param coords] as revealed, adding it to
## [member _visible_cells] and emitting [signal cell_revealed] and
## [signal EventBus.cell_revealed] (or queuing the visibility change if
## batching).
func reveal_cell(coords: Vector2i) -> void:
	var cell = get_cell(coords)
	cell.invisible = false
	_visible_cells[coords] = true
	if _batching:
		_smelly_cells[coords] = false
	else:
		cell_revealed.emit(coords)
		EventBus.cell_revealed.emit(coords)

## Sets an arbitrary [param property] on the [CellData] at [param coords] to
## [param value], if that property exists on it, and emits
## [signal cell_changed] (or queues it if batching).
func mutate(coords: Vector2i, property: String, value: Variant) -> void:
	var cell = get_cell(coords)
	if cell and property in cell:
		cell.set(property, value)
		if _batching:
			_dirty_cells[coords] = cell
		else:
			cell_changed.emit(coords, cell)
			
			
## Applies [param amount] of damage to the cell at [param coords]. If the
## cell is destroyed and has a [member CellType.destroyed_type], converts it
## to that type via [method set_cell_type]; otherwise emits
## [signal cell_changed] for the damaged cell (or queues it if batching).
## No-op on a missing or out-of-bounds cell.
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
		
## Applies [method damage_cell] with [param amount] to every in-bounds tile
## within [param radius] of [param coords].
func damage_circle(coords: Vector2i, radius: int, amount: float) -> void:
	for y in range(coords.y - radius, coords.y + radius + 1):
		for x in range(coords.x - radius, coords.x + radius + 1):
			var tbc = Vector2i(x, y)
			if _in_bounds(tbc) and Vector2(tbc - coords).length() <= radius:
				damage_cell(tbc, amount)
		
## The four cardinal direction offsets, keyed by compass label.
const CARDINAL_DIRS = {
	"N":  Vector2i( 0, -1),
	"S":  Vector2i( 0,  1),
	"E":  Vector2i( 1,  0),
	"W":  Vector2i(-1,  0),
}

## All eight direction offsets (cardinal + diagonal), keyed by compass label.
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

## Returns the neighboring [CellData] of [param coords] keyed by compass
## label, using [constant ALL_DIRS] if [param diagonal] else
## [constant CARDINAL_DIRS]. Values may be [code]null[/code] if a neighbor
## falls outside the padded grid.
func get_neighbors(coords: Vector2i, diagonal: bool = false) -> Dictionary[String, CellData]:
	var dirs = ALL_DIRS if diagonal else CARDINAL_DIRS
	var result: Dictionary[String, CellData] = {}
	for key in dirs:
		var neighbor_coords = coords + dirs[key]
		result[key] = get_cell(neighbor_coords)
	return result
	
## Returns the coordinates of neighbors of [param coords] whose terrain
## matches [param terrain], using [constant ALL_DIRS] if [param diagonal]
## else [constant CARDINAL_DIRS].
func get_neighbors_of_type(coords: Vector2i, terrain: CellType.TerrainType, diagonal: bool = false) -> Array[Vector2i]:
	var dirs = ALL_DIRS if diagonal else CARDINAL_DIRS
	var result: Array[Vector2i] = []
	for key in dirs:
		var neighbor_coords = coords + dirs[key]
		var cell = get_cell(neighbor_coords)
		if cell and cell.type and cell.type.terrain == terrain:
			result.append(neighbor_coords)
	return result
	

## Converts tile [param coords] into the flat index into [member _grid],
## accounting for [member padding].
func _idx(coords: Vector2i) -> int:
	return (coords.y + padding)* _stride + (coords.x + padding)
	
## Returns whether [param coords] falls within [member width]/[member height]
## (excluding padding).
func _in_bounds(coords: Vector2i) -> bool:
	return coords.x >= 0 and coords.x < width and coords.y >= 0 and coords.y < height

# -----------------------------------------
# ------------ helpers --------------------
# -----------------------------------------

# Converts a tile coordinate to the center pixel position of that tile.
## Converts a tile coordinate to the center pixel position of that tile.
func tile_to_world(coords: Vector2i) -> Vector2:
	return Vector2(coords * tile_size) + Vector2(tile_size * 0.5, tile_size * 0.5)

# Converts a pixel world position to the tile coordinate it falls in.
## Converts a pixel world position to the tile coordinate it falls in.
func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(world_pos / tile_size)
	
## Returns the ring of tile coordinates exactly [param radius] tiles from
## [param center] (a Bresenham-circle outline, not a filled disc). Returns
## [code][center][/code] for radius 0.
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
## Returns the nearest tile coords matching [param terrain], searching
## outward in rings from [param origin] up to [param max_radius]. Returns
## [code]Vector2i(-1, -1)[/code] if none is found.
func get_safe_coords(origin: Vector2i, terrain: CellType.TerrainType, max_radius: int = 64) -> Vector2i:
	for radius in range(0, max_radius):
		for coords in get_coords_in_radius(origin, radius):
			var cell: CellData = safe_get_cell(coords)
			if cell and cell.type and cell.type.terrain == terrain:
				return coords
	return Vector2i(-1, -1)
	
## World-space version of [method get_safe_coords]: returns the world
## position of the nearest tile matching [param terrain] near [param origin],
## or [constant Vector2.INF] if none is found.
func get_safe_world_pos(origin: Vector2, terrain: CellType.TerrainType, max_radius: int = 64) -> Vector2:
	var coords: Vector2i = get_safe_coords(world_to_tile(origin), terrain, max_radius)
	if coords == Vector2i(-1, -1):
		return Vector2.INF
	return tile_to_world(coords)

## Sets every tile within the rectangle defined by [param position] and
## [param size] to [param type_name] via [method set_cell_type].
func set_rectangle_type(position: Vector2i, size: Vector2i, type_name: StringName) -> void:
	var rectangle: Rect2i = Rect2i(position, size)
	for y in range(rectangle.position.y, rectangle.position.y + rectangle.size.y):
		for x in range(rectangle.position.x, rectangle.position.x + rectangle.size.x):
			set_cell_type(Vector2i(x, y), type_name)


## Sets every in-bounds tile within [param radius] of [param center] to
## [param type_name]. When [param filled] is [code]false[/code], only paints
## the ring outline rather than the whole disc.
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


	
	
## Hides every tile on the map (used when resetting fog-of-war, e.g. on a
## camera target change).
func hide_map() -> void:
	for y in height:
		for x in width:
			hide_cell(Vector2i(x, y))
	Log.info("Map hidden.")
	
## Hides every currently visible tile and clears [member _visible_cells].
func hide_visible_cells() -> void:
	for cell in _visible_cells.keys():
		hide_cell(cell)
	_visible_cells.clear()

## Starts batching cell-change and visibility signals instead of emitting
## them immediately; pair with [method end_batch].
func begin_batch() -> void:
	_dirty_cells.clear()
	_smelly_cells.clear()
	_batching = true
	
## Stops batching and flushes any accumulated changes as
## [signal cells_changed] and/or [signal cells_visibled] (plus
## [signal EventBus.cells_visibled]).
func end_batch() -> void:
	_batching = false
	if _dirty_cells.size() > 0:
		cells_changed.emit(_dirty_cells)
		_dirty_cells.clear()
	if _smelly_cells.size() > 0:
		cells_visibled.emit(_smelly_cells)
		EventBus.cells_visibled.emit(_smelly_cells)
		
## Returns whether the tile at [param world_pos] exists and is not currently
## marked invisible.
func is_world_pos_visible(world_pos: Vector2) -> bool:
	var cell: CellData = safe_get_cell(world_to_tile(world_pos))
	return cell != null and not cell.invisible
	

## Converts a flat [member _grid] index back into tile coordinates
## (inverse of [method _idx]).
func _idx_to_coords(idx: int) -> Vector2i:
	return Vector2i(idx % _stride - padding, idx / _stride - padding)

## Flood-fills outward from [param coords] across connected
## [constant CellType.TerrainType.GROUND] tiles, returning
## [code][flooded, border][/code] where [code]flooded[/code] is every ground
## tile reached and [code]border[/code] is the non-ground, non-out-of-bounds
## tiles adjacent to the flooded region (including diagonally). Returns two
## empty arrays if [param coords] isn't ground.
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
	
## Reveals every tile on the map (bypassing flood-fill/fog-of-war logic).
func reveal_all() -> void:
	for x in range(width):
		for y in range(height):
			reveal_cell(Vector2i(x, y))

## Reveals fog-of-war from [param coords] outward: flood-fills the connected
## ground region plus its border via [method flood_collect], then, batched
## as a single update, hides everything previously visible and reveals the
## newly flooded tiles and border.
func reveal_from(coords: Vector2i) -> void:
	var result:= flood_collect(coords)
	var flooded: Array[Vector2i] = result[0]
	var border: Array[Vector2i] = result[1]
	
	begin_batch()
	hide_visible_cells()
	for tile in flooded: reveal_cell(tile)
	for tile in border: reveal_cell(tile)
	end_batch()


## Marks every in-bounds cell as dirty and flushes them in a single batched
## [signal cells_changed]; used to force a full re-render of the grid
## (e.g. after generation).
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
