extends Component
class_name SpawnTableSpawnerComponent

@export var spawn_table: SpawnTable

func spawn_from_table() -> void:
	EntityManager.spawn_safely(spawn_table.roll_entity_type(), entity.global_position, true)

func spawn_from_table_at_pos(position: Vector2) -> void:
	EntityManager.spawn_safely(spawn_table.roll_entity_type(), position, true)
