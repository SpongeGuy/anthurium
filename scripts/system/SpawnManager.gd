extends Node
class_name SpawnManager

# -----------------------------------------------------------
# manager for entity spawns
# -----------------------------------------------------------

var spawn_interval: float = 15.0
var spawn_radius: float = 300.0
var spawn_points: int = 2500

var spawn_values: Dictionary[StringName, int] = {
	&"imp": 50,
	&"moo": 50,
	&"plopp": 50,
	&"salmon": 50,
	&"stoner": 50,
}


func _ready() -> void:
	EventBus.dawn_arrived.connect(_dawn_arrived)

func _dawn_arrived() -> void:
	return
	print("Spawning dawn lads")
	var world_boundary: Vector2 = WorldGrid.grid_size * WorldGrid.tile_size
	while spawn_points > 0:
		var spawn: StringName = spawn_values.keys().pick_random()
		EntityManager.spawn_safely(spawn, Vector2(randf() * world_boundary.x, randf() * world_boundary.y))
		spawn_points -= spawn_values[spawn]
