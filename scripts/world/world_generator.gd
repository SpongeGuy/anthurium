class_name DungeonGenerator
extends Node

@export var room_attempts: int = 30
@export var room_min_size: int = 4
@export var room_max_size: int = 10
@export var corridor_width: int = 1
@export var gap_chance: float = 0.12
@export var gap_cluster_radius: int = 1
@export var conveyor_chance: float = 0.03
@export var damage_floor_chance: float = 0.02

@export var drunk_directness: float = 0.75
@export var min_cave_size: int = 15
@export var hidden_room_max_size: int = 300

var _rng := RandomNumberGenerator.new()
var _rooms: Array[Rect2i] = []


func generate(sed: int = -1) -> void:
	if sed >= 0:
		_rng.seed = sed
	else:
		_rng.randomize()

	_rooms.clear()

	_fill_walls()
	_cellular_automata_pass()
	_cull_and_connect_caves()
	_enforce_border()
	WorldGrid.flush_all()
	EventBus.terrain_generated_successfully.emit()


func _fill_walls() -> void:
	var wall: CellType = CellTypeRegister.get_cell_type(&"wall_stone")
	for y in WorldGrid.height:
		for x in WorldGrid.width:
			WorldGrid.get_cell(Vector2i(x, y)).type = wall

func _cellular_automata_pass(iterations: int = 4) -> void:
	var wall: CellType = CellTypeRegister.get_cell_type(&"wall_stone")
	var ground: CellType = CellTypeRegister.get_cell_type(&"ground_soil")

	for y in WorldGrid.height:
		for x in WorldGrid.width:
			WorldGrid.get_cell(Vector2i(x, y)).type = wall if _rng.randf() < 0.6 else ground

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

# 3rd param is now a concrete CellType, not a TerrainType — null means "use ground_soil"
func _drunk_walk(
	from: Vector2i,
	to: Vector2i,
	cell_type: CellType = null,
	mirror_x: bool = false,
	mirror_y: bool = false,
	mirror_pivot: Vector2i = Vector2i.ZERO,
) -> void:
	if cell_type == null:
		cell_type = CellTypeRegister.get_cell_type(&"ground_soil")
	var pos = from
	var max_steps = (abs(to.x - from.x) + abs(to.y - from.y)) * 5
	for _i in max_steps:
		_stamp(pos, cell_type, mirror_x, mirror_y, mirror_pivot)
		if pos == to:
			break
		var dir: Vector2i
		if _rng.randf() < drunk_directness:
			var diff = to - pos
			dir = Vector2i(sign(diff.x), 0) if abs(diff.x) >= abs(diff.y) \
				  else Vector2i(0, sign(diff.y))
		else:
			dir = _random_cardinal_dir()
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

func _component_center(component: Array) -> Vector2i:
	var sum = Vector2i.ZERO
	for c in component:
		sum += c
	return sum / component.size()

func _cull_and_connect_caves() -> void:
	var wall: CellType = CellTypeRegister.get_cell_type(&"wall_stone")
	var components = _find_connected_components()
	components.sort_custom(func(a, b): return a.size() > b.size())

	var main_caves: Array = []
	for component in components:
		if component.size() < min_cave_size:
			for coords in component:
				WorldGrid.get_cell(coords).type = wall
		elif component.size() > hidden_room_max_size:
			main_caves.append(component)

	for i in range(main_caves.size() - 1):
		_drunk_walk(_component_center(main_caves[i]), _component_center(main_caves[i + 1]))

func _enforce_border() -> void:
	for x in WorldGrid.width:
		_make_wall(Vector2i(x, 0))
		_make_wall(Vector2i(x, WorldGrid.height - 1))
	for y in WorldGrid.height:
		_make_wall(Vector2i(0, y))
		_make_wall(Vector2i(WorldGrid.width - 1, y))

func _make_wall(coords: Vector2i) -> void:
	WorldGrid.set_cell_type(coords, &"wall_stone")

func _overlaps_any_room(candidate: Rect2i, padding: int = 0) -> bool:
	var padded = candidate.grow(padding)
	for room in _rooms:
		if padded.intersects(room):
			return true
	return false

func _random_cardinal_dir() -> Vector2i:
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	return dirs[_rng.randi() % dirs.size()]
