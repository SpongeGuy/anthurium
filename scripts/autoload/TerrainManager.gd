extends Node

func generate(generator: TerrainGenerator, rng: RandomNumberGenerator, ground_type: StringName, wall_type: StringName, indestructible_type: StringName, soft_wall_type: StringName) -> void:
	generator.generate(rng, ground_type, wall_type, indestructible_type)
	TerrainConnectivity.guarantee_reachability(soft_wall_type)
	WorldGrid.flush_all()
	EventBus.terrain_generated_successfully.emit()
	Log.info("Generated new dungeon.")
