extends Resource
class_name SpawnWave

enum CompletionCondition{REMAINING, TIME, BOSS, REMAINING_OR_TIME}


@export var completion_condition: CompletionCondition = CompletionCondition.REMAINING_OR_TIME
@export var budget: int = 10
@export var entries: Array[SpawnEntry] = []
@export var time_limit: float = 30
@export_range(0.0, 1.0) var remaining_limit_ratio: float = 0.2
@export var boss_id: StringName
## if true, when this wave's condition is met, the wave will start over.
@export var loop: bool = false
