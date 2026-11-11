class_name CaveTerrainGenerator extends TerrainGenerator
@export var drunk_directness: float = 0.75
@export var min_cave_ratio: float = 0.015
@export var hidden_room_max_ratio: float = 0.2

var _min_cave_size: int
var _hidden_room_max_size: int

func generate(rng: RandomNumberGenerator, ground_type: StringName, wall_type: StringName, indestructible_type: StringName) -> void:
	var total_tiles: int = WorldGrid.width * WorldGrid.height
	_min_cave_size = maxi(6, roundi(total_tiles * min_cave_ratio))
	_hidden_room_max_size = roundi(total_tiles * hidden_room_max_ratio)

	_fill_walls(wall_type)
	_cellular_automata_pass(rng, ground_type, wall_type)
	_cull_and_connect_caves(rng, ground_type, wall_type)
	enforce_border(indestructible_type)

func _fill_walls(wall_type: StringName) -> void:
	var wall: CellType = CellTypeRegistry.get_cell_type(wall_type)
	for y in WorldGrid.height:
		for x in WorldGrid.width:
			WorldGrid.get_cell(Vector2i(x, y)).type = wall

func _cellular_automata_pass(rng: RandomNumberGenerator, ground_type: StringName, wall_type: StringName, iterations: int = 4) -> void:
	var wall: CellType = CellTypeRegistry.get_cell_type(wall_type)
	var ground: CellType = CellTypeRegistry.get_cell_type(ground_type)

	for y in WorldGrid.height:
		for x in WorldGrid.width:
			WorldGrid.get_cell(Vector2i(x, y)).type = wall if rng.randf() < 0.6 else ground

	for _i in iterations:
		var next: Dictionary[Vector2i, CellType.TerrainType] = {}
		for y in range(1, WorldGrid.height - 1):
			for x in range(1, WorldGrid.width - 1):
				var coords := Vector2i(x, y)
				var wall_count := WorldGrid.get_neighbors_of_type(coords, CellType.TerrainType.WALL, true).size()
				next[coords] = CellType.TerrainType.WALL if wall_count >= 5 else CellType.TerrainType.GROUND
		for coords in next:
			WorldGrid.get_cell(coords).type = wall if next[coords] == CellType.TerrainType.WALL else ground

func _drunk_walk(from: Vector2i, to: Vector2i, rng: RandomNumberGenerator, cell_type: CellType, mirror_x: bool = false, mirror_y: bool = false, mirror_pivot: Vector2i = Vector2i.ZERO) -> void:
	var pos := from
	var max_steps := (absi(to.x - from.x) + absi(to.y - from.y)) * 5
	for _i in max_steps:
		_stamp(pos, cell_type, mirror_x, mirror_y, mirror_pivot)
		if pos == to:
			break
		var dir: Vector2i
		if rng.randf() < drunk_directness:
			var diff := to - pos
			dir = Vector2i(sign(diff.x), 0) if absi(diff.x) >= absi(diff.y) else Vector2i(0, sign(diff.y))
		else:
			dir = _random_cardinal_dir(rng)
		pos = (pos + dir).clamp(Vector2i(1, 1), Vector2i(WorldGrid.width - 2, WorldGrid.height - 2))

func _stamp(pos: Vector2i, cell_type: CellType, mirror_x: bool, mirror_y: bool, pivot: Vector2i) -> void:
	_try_set_type(pos, cell_type)
	if mirror_x:
		_try_set_type(Vector2i(2 * pivot.x - pos.x, pos.y), cell_type)
	if mirror_y:
		_try_set_type(Vector2i(pos.x, 2 * pivot.y - pos.y), cell_type)
	if mirror_x and mirror_y:
		_try_set_type(Vector2i(2 * pivot.x - pos.x, 2 * pivot.y - pos.y), cell_type)

func _try_set_type(coords: Vector2i, cell_type: CellType) -> void:
	if WorldGrid._in_bounds(coords):
		WorldGrid.get_cell(coords).type = cell_type

func _find_connected_components() -> Array:
	var visited: Dictionary = {}
	var components: Array = []
	for y in range(1, WorldGrid.height - 1):
		for x in range(1, WorldGrid.width - 1):
			var coords := Vector2i(x, y)
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

func _component_center(component: Array) -> Vector2i:
	var sum := Vector2i.ZERO
	for c in component:
		sum += c
	return sum / component.size()

func _cull_and_connect_caves(rng: RandomNumberGenerator, ground_type: StringName, wall_type: StringName) -> void:
	var wall: CellType = CellTypeRegistry.get_cell_type(wall_type)
	var ground: CellType = CellTypeRegistry.get_cell_type(ground_type)
	var components := _find_connected_components()
	components.sort_custom(func(a, b): return a.size() > b.size())

	var main_caves: Array = []
	for component in components:
		if component.size() < _min_cave_size:
			for coords in component:
				WorldGrid.get_cell(coords).type = wall
		elif component.size() > _hidden_room_max_size:
			main_caves.append(component)

	if main_caves.is_empty() and not components.is_empty():
		for component in components:
			if component.size() >= _min_cave_size:
				main_caves.append(component)
				break

	for i in range(main_caves.size() - 1):
		_drunk_walk(_component_center(main_caves[i]), _component_center(main_caves[i + 1]), rng, ground)



func _random_cardinal_dir(rng: RandomNumberGenerator) -> Vector2i:
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	return dirs[rng.randi() % dirs.size()]
