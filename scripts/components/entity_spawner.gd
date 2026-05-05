extends Component
class_name EntitySpawner

@export var entity_type: StringName

func spawn_at(position: Vector2) -> void:
	EntityManager.spawn_safely(entity_type, position)
