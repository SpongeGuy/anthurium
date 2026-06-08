class_name DungeonGenerator
extends Node

# -------------------------------------------------------
# Tuning parameters
# -------------------------------------------------------

@export var room_attempts: int = 30       # how many rooms we try to place
@export var room_min_size: int = 4
@export var room_max_size: int = 10
@export var corridor_width: int = 1
@export var gap_chance: float = 0.12      # per-cell chance inside rooms (xx%)
@export var gap_cluster_radius: int = 1   # gaps tend to cluster slightly
@export var conveyor_chance: float = 0.03 # some ground tiles become conveyors
@export var damage_floor_chance: float = 0.02

@export var drunk_directness: float = 0.75   # probability to step toward destination
@export var min_cave_size: int = 15           # smaller than this → cull (noise)
@export var hidden_room_max_size: int = 300    # between min and this → leave disconnected

var _rng := RandomNumberGenerator.new()
var _rooms: Array[Rect2i] = []


# -------------------------------------------------------
# Entry point
# -------------------------------------------------------

func generate(sed: int = -1) -> void:
	if sed >= 0:
		_rng.seed = sed
	else:
		_rng.randomize()

	_rooms.clear()

	_fill_walls()
	_cellular_automata_pass()
	_cull_and_connect_caves()
	#var center = Vector2i(WorldGrid.width / 2, WorldGrid.height / 2)
	#_drunk_walk(center, Vector2i(5, 5), CellData.TerrainType.GROUND, true, true, center)
	_enforce_border()
	WorldGrid.flush_all()
	EventBus.terrain_generated_successfully.emit()
	


func _set_cell_delayed(coords: Vector2i, cell: CellData) -> void:
	WorldGrid.set_cell(coords, cell)
	
	get_tree().create_timer(0.01).timeout

# -------------------------------------------------------
# Passes
# -------------------------------------------------------

func _fill_walls() -> void:
	for y in WorldGrid.height:
		for x in WorldGrid.width:
			WorldGrid.get_cell(Vector2i(x, y)).terrain = CellData.TerrainType.WALL

func _cellular_automata_pass(iterations: int = 4) -> void:
	# Seed — mutate directly, no signals yet
	for y in WorldGrid.height:
		for x in WorldGrid.width:
			WorldGrid.get_cell(Vector2i(x, y)).terrain = \
				CellData.TerrainType.WALL if _rng.randf() < 0.6 \
				else CellData.TerrainType.GROUND

	# Smooth
	for _i in iterations:
		var next: Dictionary[Vector2i, CellData.TerrainType] = {}
		for y in range(1, WorldGrid.height - 1):
			for x in range(1, WorldGrid.width - 1):
				var coords = Vector2i(x, y)
				var wall_count = WorldGrid.get_neighbors_of_type(
					coords, CellData.TerrainType.WALL, true
				).size()
				next[coords] = CellData.TerrainType.WALL if wall_count >= 5 \
								else CellData.TerrainType.GROUND
		for coords in next:
			WorldGrid.get_cell(coords).terrain = next[coords]

func _drunk_walk(
	from: Vector2i,
	to: Vector2i,
	terrain: CellData.TerrainType = CellData.TerrainType.GROUND,
	mirror_x: bool = false,
	mirror_y: bool = false,
	mirror_pivot: Vector2i = Vector2i.ZERO,
) -> void:
	var pos = from
	var max_steps = (abs(to.x - from.x) + abs(to.y - from.y)) * 5
	for _i in max_steps:
		_stamp(pos, terrain, mirror_x, mirror_y, mirror_pivot)
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

## Carves pos and any mirror positions. mirror_x reflects across the
## vertical axis at pivot.x; mirror_y reflects across the horizontal
## axis at pivot.y. Both active = 4-fold symmetry.
func _stamp(
	pos: Vector2i,
	terrain: CellData.TerrainType,
	mirror_x: bool,
	mirror_y: bool,
	pivot: Vector2i
) -> void:
	_try_set_terrain(pos, terrain)
	if mirror_x:
		_try_set_terrain(Vector2i(2 * pivot.x - pos.x, pos.y), terrain)
	if mirror_y:
		_try_set_terrain(Vector2i(pos.x, 2 * pivot.y - pos.y), terrain)
	if mirror_x and mirror_y:
		_try_set_terrain(Vector2i(2 * pivot.x - pos.x, 2 * pivot.y - pos.y), terrain)


func _try_set_terrain(coords: Vector2i, terrain: CellData.TerrainType) -> void:
	if WorldGrid._in_bounds(coords):
		WorldGrid.get_cell(coords).terrain = terrain

func _find_connected_components() -> Array:
	var visited: Dictionary = {}
	var components: Array = []

	for y in range(1, WorldGrid.height - 1):
		for x in range(1, WorldGrid.width - 1):
			var coords = Vector2i(x, y)
			if visited.has(coords):
				continue
			if WorldGrid.get_cell(coords).terrain != CellData.TerrainType.GROUND:
				continue

			var component: Array[Vector2i] = []
			var queue: Array[Vector2i] = [coords]
			visited[coords] = true

			while not queue.is_empty():
				var current: Vector2i = queue.pop_back()
				component.append(current)
				for neighbor in WorldGrid.get_neighbors_of_type(
						current, CellData.TerrainType.GROUND):
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
	var components = _find_connected_components()
	components.sort_custom(func(a, b): return a.size() > b.size())

	var main_caves: Array = []

	for component in components:
		if component.size() < min_cave_size:
			# Too small — noise, fill it back
			for coords in component:
				WorldGrid.get_cell(coords).terrain = CellData.TerrainType.WALL
		elif component.size() > hidden_room_max_size:
			# Large enough to be a main cave — connect it
			main_caves.append(component)
		# else: intentionally left disconnected — becomes a hidden room

	for i in range(main_caves.size() - 1):
		_drunk_walk(
			_component_center(main_caves[i]),
			_component_center(main_caves[i + 1])
		)







func _place_rooms() -> void:
	for _i in room_attempts:
		var w = _rng.randi_range(room_min_size, room_max_size)
		var h = _rng.randi_range(room_min_size, room_max_size)
		# Keep away from border by 1
		var x = _rng.randi_range(1, WorldGrid.width - w - 2)
		var y = _rng.randi_range(1, WorldGrid.height - h - 2)
		var candidate = Rect2i(x, y, w, h)

		var padding: int = 1
		if _overlaps_any_room(candidate, padding):
			continue

		_rooms.append(candidate)
		await _carve_room(candidate)



func _carve_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			var cell = CellData.new()
			cell.terrain = CellData.TerrainType.GROUND
			await _set_cell_delayed(Vector2i(x, y), cell)


func _connect_rooms() -> void:
	if _rooms.size() < 2:
		return

	# Connect each room to the next in the list (simple guaranteed connectivity)
	for i in range(_rooms.size() - 1):
		var a_center = _rooms[i].get_center()
		var b_center = _rooms[i + 1].get_center()
		await _carve_corridor(Vector2i(a_center), Vector2i(b_center))


func _carve_corridor(from: Vector2i, to: Vector2i) -> void:
	# L-shaped corridor: horizontal then vertical
	# Randomly decide which leg goes first
	if _rng.randi() % 2 == 0:
		_carve_h_corridor(from.y, from.x, to.x)
		_carve_v_corridor(to.x, from.y, to.y)
	else:
		_carve_v_corridor(from.x, from.y, to.y)
		_carve_h_corridor(to.y, from.x, to.x)


func _carve_h_corridor(row: int, x_from: int, x_to: int) -> void:
	var x_min = min(x_from, x_to)
	var x_max = max(x_from, x_to)
	for x in range(x_min, x_max + 1):
		for offset in range(corridor_width):
			var y = row + offset
			if WorldGrid._in_bounds(Vector2i(x, y)):
				var cell = CellData.new()
				cell.terrain = CellData.TerrainType.GROUND
				_set_cell_delayed(Vector2i(x, y), cell)


func _carve_v_corridor(col: int, y_from: int, y_to: int) -> void:
	var y_min = min(y_from, y_to)
	var y_max = max(y_from, y_to)
	for y in range(y_min, y_max + 1):
		for offset in range(corridor_width):
			var x = col + offset
			if WorldGrid._in_bounds(Vector2i(x, y)):
				var cell = CellData.new()
				cell.terrain = CellData.TerrainType.GROUND
				_set_cell_delayed(Vector2i(x, y), cell)


func _scatter_gaps() -> void:
	# Only place gaps inside rooms, not corridors or near room edges
	for room in _rooms:
		# Inset by 1 to avoid gaps directly on room borders
		var inset = room.grow(-1)
		if inset.size.x <= 0 or inset.size.y <= 0:
			continue

		for y in range(inset.position.y, inset.position.y + inset.size.y):
			for x in range(inset.position.x, inset.position.x + inset.size.x):
				var coords = Vector2i(x, y)
				if _rng.randf() < gap_chance:
					_place_gap_cluster(coords)


func _place_gap_cluster(center: Vector2i) -> void:
	# Place a gap at center, with a chance to spread to neighbors
	_place_gap(center)
	if gap_cluster_radius < 1:
		return

	var neighbors = WorldGrid.get_neighbors(center)
	for key in neighbors:
		var cell: CellData = neighbors[key]
		if cell and cell.terrain == CellData.TerrainType.GROUND:
			if _rng.randf() < 0.3:  # 30% spread chance per neighbor
				_place_gap(center + WorldGrid.CARDINAL_DIRS[key])


func _place_gap(coords: Vector2i) -> void:
	var cell = WorldGrid.get_cell(coords)
	if cell == null or cell.terrain != CellData.TerrainType.GROUND:
		return
	cell.terrain = CellData.TerrainType.GAP
	cell.fall_damage = _rng.randf_range(0.0, 20.0)
	cell.kill_on_fall = _rng.randf() < 0.15   # 15% chance of lethal gap
	WorldGrid.cell_changed.emit(coords, cell)


func _scatter_ground_effects() -> void:
	for y in WorldGrid.height:
		for x in WorldGrid.width:
			var coords = Vector2i(x, y)
			var cell = WorldGrid.get_cell(coords)
			if cell == null or cell.terrain != CellData.TerrainType.GROUND:
				continue

			# Conveyor belts — appear in small streaks
			if _rng.randf() < conveyor_chance:
				var dir = _random_cardinal_dir()
				var streak_len = _rng.randi_range(2, 5)
				for i in streak_len:
					var sc = coords + dir * i
					var sc_cell = WorldGrid.get_cell(sc)
					if sc_cell and sc_cell.terrain == CellData.TerrainType.GROUND:
						sc_cell.conveyor_velocity = Vector2(dir) * _rng.randf_range(60.0, 180.0)
						WorldGrid.cell_changed.emit(sc, sc_cell)

			# Damage floors — hot coals, acid, etc.
			elif _rng.randf() < damage_floor_chance:
				cell.contact_damage = _rng.randf_range(2.0, 8.0)
				WorldGrid.cell_changed.emit(coords, cell)


func _enforce_border() -> void:
	# Guarantee the outermost ring is always solid wall
	for x in WorldGrid.width:
		_make_wall(Vector2i(x, 0))
		_make_wall(Vector2i(x, WorldGrid.height - 1))
	for y in WorldGrid.height:
		_make_wall(Vector2i(0, y))
		_make_wall(Vector2i(WorldGrid.width - 1, y))


func _make_wall(coords: Vector2i) -> void:
	var cell = WorldGrid.get_cell(coords)
	if cell:
		cell.terrain = CellData.TerrainType.WALL
		WorldGrid.cell_changed.emit(coords, cell)


# -------------------------------------------------------
# Helpers
# -------------------------------------------------------

func _overlaps_any_room(candidate: Rect2i, padding: int = 0) -> bool:
	var padded = candidate.grow(padding)
	for room in _rooms:
		if padded.intersects(room):
			return true
	return false


func _random_cardinal_dir() -> Vector2i:
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	return dirs[_rng.randi() % dirs.size()]
