extends Node

func generate(generator: TerrainGenerator, rng: RandomNumberGenerator, ground_type: StringName, wall_type: StringName, indestructible_type: StringName, soft_wall_type: StringName) -> void:
	generator.generate(rng, ground_type, wall_type, indestructible_type)
	TerrainConnectivity.guarantee_reachability(soft_wall_type)
	WorldGrid.flush_all()
	EventBus.terrain_generated_successfully.emit()
	Log.info("Generated new dungeon.")


func query_for_tile_type(type: CellType.TerrainType) -> Array[Vector2i]:
	var query: Array[Vector2i] = []
	for x in range(WorldGrid.width):
		for y in range(WorldGrid.height):
			if WorldGrid.get_cell(Vector2i(x, y)).type.terrain == type:
				query.append(Vector2i(x, y))
	return query
