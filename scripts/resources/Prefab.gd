class_name Prefab extends Resource

@export var width: int = 1
@export var height: int = 1

## Row-major, length must be width * height
@export var cells: Array[PrefabCell] = []

func get_width() -> int: return width
func get_height() -> int: return height

func get_cell(x: int, y: int) -> PrefabCell:
	return cells[y * width + x]

func stamp(origin: Vector2i) -> void:
	assert(cells.size() == width * height, "prefab cells don't match width * height")
	for y in height:
		for x in width:
			var cell: PrefabCell = get_cell(x, y)
			if cell == null:
				continue
			var coords: Vector2i = origin + Vector2i(x, y)
			if cell.cell_type != &"":
				WorldGrid.set_cell_type(coords, cell.cell_type)
			for id in cell.entities:
				EntityManager.simple_spawn_tile(id, coords)
