extends EntitySpawner
class_name AnthuriumGrowthNodeSpawnerComponent

var ready_to_spawn_part: bool = false
var part_to_spawn: StringName

func _on_registered() -> void:
	part_to_spawn = AnthuriumBrain.resolve_needed_part()

func spawn_at(position: Vector2) -> void:
	if ready_to_spawn_part:
		EntityManager.spawn_safely(part_to_spawn, position)
	else:
		EntityManager.spawn_safely(entity_type, position)
