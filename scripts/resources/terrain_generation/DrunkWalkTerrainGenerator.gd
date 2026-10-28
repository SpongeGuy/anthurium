class_name DrunkWalkTerrainGenerator extends TerrainGenerator
@export var path_count: int = 6
@export var directness: float = 0.6
@export var symmetry: TerrainSymmetry.Mode = TerrainSymmetry.Mode.MIRROR_XY

func generate(rng: RandomNumberGenerator, ground_type: StringName, wall_type: StringName, indestructible_type: StringName) -> void:
	var wall: CellType = CellTypeRegistry.get_cell_type(wall_type)
	var ground: CellType = CellTypeRegistry.get_cell_type(ground_type)

	for y in WorldGrid.height:
		for x in WorldGrid.width:
			WorldGrid.get_cell(Vector2i(x, y)).type = wall

	for _i in path_count:
		var from := Vector2i(rng.randi_range(1, WorldGrid.width - 2), rng.randi_range(1, WorldGrid.height - 2))
		var to := Vector2i(rng.randi_range(1, WorldGrid.width - 2), rng.randi_range(1, WorldGrid.height - 2))
		_carve(from, to, rng, ground, directness)
	
	enforce_border(indestructible_type)

func _carve(from: Vector2i, to: Vector2i, rng: RandomNumberGenerator, ground: CellType, directness: float) -> void:
	var pos := from
	var max_steps := (absi(to.x - from.x) + absi(to.y - from.y)) * 5
	for _i in max_steps:
		if WorldGrid._in_bounds(pos):
			TerrainSymmetry.stamp(pos, ground, symmetry)
		if pos == to:
			break
		var dir: Vector2i
		if rng.randf() < directness:
			var diff := to - pos
			dir = Vector2i(sign(diff.x), 0) if absi(diff.x) >= absi(diff.y) else Vector2i(0, sign(diff.y))
		else:
			var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			dir = dirs[rng.randi() % dirs.size()]
		pos = (pos + dir).clamp(Vector2i(1, 1), Vector2i(WorldGrid.width - 2, WorldGrid.height - 2))
