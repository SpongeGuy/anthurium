class_name TerrainConnectivity

## ensures every GROUND region is reachable from the largest one by finding the shortest path
## of non-ground tiles separating each isolated region and converting jsut that path to [param soft_wall_type].
## whatever currently seals a pocket becomes soft wall along the minimal correcting path
static func guarantee_reachability(soft_wall_type: StringName) -> void:
	var components: Array = _find_ground_components()
	if components.size() <= 1:
		return
	components.sort_custom(func(a, b): return a.size() > b.size())
	
	var reachable: Dictionary[Vector2i, bool] = {}
	for coords in components[0]:
		reachable[coords] = true
	
	var soft_wall: CellType = CellTypeRegistry.get_cell_type(soft_wall_type)
	for i in range(1, components.size()):
		var path: Array[Vector2i] = _shortest_wall_path(reachable, components[i])
		for coords in path:
			WorldGrid.get_cell(coords).type = soft_wall
			reachable[coords] = true
		for coords in components[i]:
			reachable[coords] = true


static func _find_ground_components() -> Array:
	var visited: Dictionary = {}
	var components: Array = []
	for y in range(1, WorldGrid.height - 1):
		for x in range(1, WorldGrid.width - 1):
			var coords: Vector2i = Vector2i(x, y)
			if visited.has(coords) or WorldGrid.get_cell(coords).type.terrain != CellType.TerrainType.GROUND:
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

## multi-source BFS outward from `reachable` over non-ground tiles until a tile adjacent to `target` is found.
## returns only the connecting wall tiles (the endpoint ground is not included)
static func _shortest_wall_path(reachable: Dictionary[Vector2i, bool], target: Array[Vector2i]) -> Array[Vector2i]:
	var target_set: Dictionary[Vector2i, bool] = {}
	for t in target:
		target_set[t] = true
	
	var came_from: Dictionary[Vector2i, Vector2i] = {}
	var visited: Dictionary[Vector2i, bool] = {}
	var frontier: Array[Vector2i] = []
	
	for coords in reachable.keys():
		for neighbor in _cardinal_neighbors(coords):
			if not WorldGrid._in_bounds(neighbor) or reachable.has(neighbor) or visited.has(neighbor):
				continue
			visited[neighbor] = true
			came_from[neighbor] = coords
			frontier.append(neighbor)
		
	while not frontier.is_empty():
		var next_frontier: Array[Vector2i] = []
		for current in frontier:
			if target_set.has(current):
				return _reconstruct(came_from, current, reachable)
			for neighbor in _cardinal_neighbors(current):
				if not WorldGrid._in_bounds(neighbor) or reachable.has(neighbor) or visited.has(neighbor):
					continue
				visited[neighbor] = true
				came_from[neighbor] = current
				next_frontier.append(neighbor)
		frontier = next_frontier
	return [] # this should not happen in a bordered grid


static func _reconstruct(came_from: Dictionary[Vector2i, Vector2i], matched_target: Vector2i, reachable: Dictionary[Vector2i, bool]) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current: Vector2i = came_from[matched_target]
	while came_from.has(current) and not reachable.has(came_from[current]):
		path.append(current)
		current = came_from[current]
	if not reachable.has(current):
		path.append(current)
	return path

static func _cardinal_neighbors(coords: Vector2i) -> Array[Vector2i]:
	return [coords + Vector2i.UP, coords + Vector2i.DOWN, coords + Vector2i.LEFT, coords + Vector2i.RIGHT]
