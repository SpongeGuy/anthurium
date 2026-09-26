class_name WaveDefinition
extends Resource
@export var entity_pool: EntityPool
@export var point_budget: float = 100.0
@export var spawn_interval_range: Vector2 = Vector2(0.1, 1.0)
@export var completion_factory: CompletionFactory
@export var spawn_modifiers: Array[SpawnModifier] = []
