extends Component
class_name EntitySpawner

@export var entities_to_spawn: Array[StringName] = []
@export var spawn_chance: Array[float] = []

func spawn_at(position: Vector2) -> void:
	for i in range(entities_to_spawn.size()):
		if randf() < spawn_chance[i]:
			EntityManager.spawn_safely(entities_to_spawn[i], position + Vector2(randf_range(-8, 8), randf_range(-8, 8)))



func spawn_at_entity() -> void:
	for i in range(entities_to_spawn.size()):
		if randf() < spawn_chance[i]:
			EntityManager.spawn_safely(entities_to_spawn[i], entity.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8)))
