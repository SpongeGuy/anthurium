## Autoload: DungeonGenerator
##
## Procedurally fills [WorldGrid] with a cave-like layout: a cellular-
## automata pass carves rough caves out of solid rock, small pockets are
## culled back to wall, and the remaining large caves are connected with
## drunkard's-walk tunnels. Call [method generate] once [WorldGrid] has been
## sized via [method WorldGrid.init_grid].
extends Node


## How strongly [method _drunk_walk] biases its steps toward the target
## versus a random direction, in [code][0, 1][/code] (1.0 = always step
## toward the target).
var drunk_directness: float = 0.75
## Connected cave regions smaller than this ratio * map area are filled back in as
## wall during [method _cull_and_connect_caves].
var min_cave_ratio: float = 0.015
## Connected cave regions larger than this ratio * map area are treated as "hidden
## rooms" and excluded from the main, tunnel-connected cave network.
var hidden_room_max_ratio: float = 0.2


## Reserved for future room-placement logic; currently unused by the cave
## generation path.
var _rooms: Array[Rect2i] = []

var min_cave_size: int = 15
var hidden_room_max_size: int = 300


## Runs the full generation pipeline against the current [WorldGrid]: seeds
## the RNG (randomly unless [param sed] is given), carves walls, runs the
## cellular-automata cave pass, culls small pockets and connects the main
## caves, stamps a solid border, and flushes the result to [WorldGrid] for
## rendering. Emits [signal EventBus.terrain_generated_successfully] when
## done.
func generate(rng: RandomNumberGenerator) -> void:
	_rooms.clear()
	
	var total_tiles: int = WorldGrid.width * WorldGrid.height
	min_cave_size = maxi(6, roundi(total_tiles * min_cave_ratio))
	hidden_room_max_size = roundi(total_tiles * hidden_room_max_ratio)

	_fill_walls()
	_cellular_automata_pass(rng)
	_cull_and_connect_caves(rng)
	_enforce_border()
	WorldGrid.flush_all()
	EventBus.terrain_generated_successfully.emit()
	Log.info("Generated new dungeon.")


## Fills every tile in [WorldGrid] with stone wall as a starting point.
func _fill_walls() -> void:
	var wall: CellType = CellTypeRegistry.get_cell_type(&"wall_stone")
	for y in WorldGrid.height:
		for x in WorldGrid.width:
			WorldGrid.get_cell(Vector2i(x, y)).type = wall

## Randomly seeds the grid as ~60% wall / 40% ground, then runs [param iterations]
## passes of a 4-8 cellular automata rule (a tile becomes wall if 5+ of its
## 8 neighbors are wall) to smooth the noise into organic-looking caves.
func _cellular_automata_pass(rng: RandomNumberGenerator, iterations: int = 4) -> void:
	var wall: CellType = CellTypeRegistry.get_cell_type(&"wall_stone")
	var ground: CellType = CellTypeRegistry.get_cell_type(&"ground_soil")

	for y in WorldGrid.height:
		for x in WorldGrid.width:
			WorldGrid.get_cell(Vector2i(x, y)).type = wall if rng.randf() < 0.6 else ground

	for _i in iterations:
		var next: Dictionary[Vector2i, CellType.TerrainType] = {}
		for y in range(1, WorldGrid.height - 1):
			for x in range(1, WorldGrid.width - 1):
				var coords = Vector2i(x, y)
				var wall_count = WorldGrid.get_neighbors_of_type(
					coords, CellType.TerrainType.WALL, true
				).size()
				next[coords] = CellType.TerrainType.WALL if wall_count >= 5 \
								else CellType.TerrainType.GROUND
		for coords in next:
			WorldGrid.get_cell(coords).type = wall if next[coords] == CellType.TerrainType.WALL else ground

# 3rd param is now a concrete CellType, not a TerrainType; null means "use ground_soil"
## Carves a path of [param cell_type] (defaulting to
## [code]&"ground_soil"[/code]) from [param from] to [param to] using a
## biased random walk (see [member drunk_directness]), optionally mirroring
## every stamped tile across [param mirror_pivot] on the X and/or Y axis.
## Steps are capped at 5x the Manhattan distance between the endpoints so a
## bad walk can't run away.
func _drunk_walk(
	from: Vector2i,
	to: Vector2i,
	rng: RandomNumberGenerator,
	cell_type: CellType = null,
	mirror_x: bool = false,
	mirror_y: bool = false,
	mirror_pivot: Vector2i = Vector2i.ZERO,
) -> void:
	if cell_type == null:
		cell_type = CellTypeRegistry.get_cell_type(&"ground_soil")
	var pos = from
	var max_steps = (abs(to.x - from.x) + abs(to.y - from.y)) * 5
	for _i in max_steps:
		_stamp(pos, cell_type, mirror_x, mirror_y, mirror_pivot)
		if pos == to:
			break
		var dir: Vector2i
		if rng.randf() < drunk_directness:
			var diff = to - pos
			dir = Vector2i(sign(diff.x), 0) if abs(diff.x) >= abs(diff.y) \
				  else Vector2i(0, sign(diff.y))
		else:
			dir = _random_cardinal_dir(rng)
		pos = (pos + dir).clamp(Vector2i(1, 1), Vector2i(WorldGrid.width - 2, WorldGrid.height - 2))

## Sets the tile at [param pos] to [param cell_type], plus its mirrored
## counterpart(s) across [param pivot] on whichever of [param mirror_x] /
## [param mirror_y] are enabled (both together also mirrors diagonally).
func _stamp(pos: Vector2i, cell_type: CellType, mirror_x: bool, mirror_y: bool, pivot: Vector2i) -> void:
	_try_set_type(pos, cell_type)
	if mirror_x:
		_try_set_type(Vector2i(2 * pivot.x - pos.x, pos.y), cell_type)
	if mirror_y:
		_try_set_type(Vector2i(pos.x, 2 * pivot.y - pos.y), cell_type)
	if mirror_x and mirror_y:
		_try_set_type(Vector2i(2 * pivot.x - pos.x, 2 * pivot.y - pos.y), cell_type)

## Sets the tile at [param coords] to [param cell_type] if it's in bounds;
## silently does nothing otherwise.
func _try_set_type(coords: Vector2i, cell_type: CellType) -> void:
	if WorldGrid._in_bounds(coords):
		WorldGrid.get_cell(coords).type = cell_type

## Flood-fills the interior of the grid to find every connected group of
## [constant CellType.TerrainType.GROUND] tiles. Returns an [Array] of
## [Array][Vector2i] components.
func _find_connected_components() -> Array:
	var visited: Dictionary = {}
	var components: Array = []

	for y in range(1, WorldGrid.height - 1):
		for x in range(1, WorldGrid.width - 1):
			var coords = Vector2i(x, y)
			if visited.has(coords):
				continue
			if WorldGrid.get_cell(coords).type.terrain != CellType.TerrainType.GROUND:
				continue

			var component: Array[Vector2i] = []
			var queue: Array[Vector2i] = [coords]
			visited[coords] = true

			while not queue.is_empty():
				var current: Vector2i = queue.pop_back()
				component.append(current)
				for neighbor in WorldGrid.get_neighbors_of_type(current, CellType.TerrainType.GROUND):
					if not visited.has(neighbor):
						visited[neighbor] = true
						queue.append(neighbor)

			components.append(component)

	return components

## Returns the (integer, rounded-down) centroid of [param component]'s tile
## coordinates.
func _component_center(component: Array) -> Vector2i:
	var sum = Vector2i.ZERO
	for c in component:
		sum += c
	return sum / component.size()

## Finds all connected cave components, fills back to wall any smaller than
## [member min_cave_size], collects the large "main" caves (larger than
## [member hidden_room_max_size]) sorted biggest-first, and connects each
## consecutive pair of main caves with a [method _drunk_walk] tunnel between
## their centers.
func _cull_and_connect_caves(rng: RandomNumberGenerator) -> void:
	var wall: CellType = CellTypeRegistry.get_cell_type(&"wall_stone")
	var components = _find_connected_components()
	components.sort_custom(func(a, b): return a.size() > b.size())

	var main_caves: Array = []
	for component in components:
		if component.size() < min_cave_size:
			for coords in component:
				WorldGrid.get_cell(coords).type = wall
		elif component.size() > hidden_room_max_size:
			main_caves.append(component)
			
	if main_caves.is_empty() and not components.is_empty():
		for component in components:
			if component.size() >= min_cave_size:
				main_caves.append(component)
				break

	for i in range(main_caves.size() - 1):
		_drunk_walk(_component_center(main_caves[i]), _component_center(main_caves[i + 1]), rng)

## Stamps a solid stone-wall border around the full extent of the grid.
func _enforce_border() -> void:
	for x in WorldGrid.width:
		_make_wall(Vector2i(x, 0))
		_make_wall(Vector2i(x, WorldGrid.height - 1))
	for y in WorldGrid.height:
		_make_wall(Vector2i(0, y))
		_make_wall(Vector2i(WorldGrid.width - 1, y))

## Sets the tile at [param coords] to stone wall.
func _make_wall(coords: Vector2i) -> void:
	WorldGrid.set_cell_type(coords, &"indestructible_wall")

## Returns whether [param candidate] (grown by [param padding]) overlaps any
## room in [member _rooms]. Reserved for future room-based generation;
## unused by the current cave pipeline.
func _overlaps_any_room(candidate: Rect2i, padding: int = 0) -> bool:
	var padded = candidate.grow(padding)
	for room in _rooms:
		if padded.intersects(room):
			return true
	return false

## Returns a random cardinal direction as a [Vector2i] unit step.
func _random_cardinal_dir(rng: RandomNumberGenerator) -> Vector2i:
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	return dirs[rng.randi() % dirs.size()]
