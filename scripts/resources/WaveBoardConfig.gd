extends Resource
class_name WaveBoardConfig

@export var max_waves: int = 5
@export var base_point_budget: int = 10
@export var point_budget_growth: float = 1.3 # budget compounds per wave

const SPAWN_TRIES: int = 100

@export var creature_point_values: Dictionary[StringName, int] = {
	"blimble": 1,
	"meat_shank": 2,
	"blom_bulb": 3
}

func get_point_budget(wave_index: int) -> int:
	return roundi(base_point_budget * pow(point_budget_growth, wave_index))
	
## greedily fills a spawn list until the budget's exhausted or nothing affordable remains
func build_spawn_list(budget: int) -> Array[StringName]:
	var pool: Array = creature_point_values.keys()
	var list: Array[StringName] = []
	var remaining: int = budget
	var safety: int = 0
	while remaining > 0 and safety < 200:
		safety += 1
		var affordable: Array = pool.filter(func(n): return creature_point_values[n] <= remaining)
		if affordable.is_empty():
			break
		var choice: StringName = affordable[randi() % affordable.size()]
		list.append(choice)
		remaining -= creature_point_values[choice]
	return list
	
func get_spawn_position() -> Vector2i:
	for i in range(SPAWN_TRIES):
		var pos = Vector2i(randi_range(0, WorldGrid.width - 1), randi_range(0, WorldGrid.height - 1))
		if WorldGrid.get_cell(pos).type.terrain != CellType.TerrainType.GROUND:
			return pos
	Log.warn("Could not find safe position, spawning at world center!")
	return WorldGrid.get_center()
