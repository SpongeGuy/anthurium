extends Resource
class_name SpawnEntry

@export var entity_id: StringName
@export_range(1, 100) var cost: int = 1
@export var weight: float = 1.0
@export var min_level: int = 1
